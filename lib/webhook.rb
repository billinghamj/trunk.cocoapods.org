# A minimal web hook implementation.
#
# Use Webhook.call("message") in the server.
# Use Webhook.run in a worker process.
#
# Note that Webhook.call will currently block if there is no worker process.
#
class Webhook
  # List of attached web hook URLs.
  #
  URLS = [
    "http://cocoadocs.org/hooks/trunk/#{ENV['OUTGOING_HOOK_PATH']}",
    # "http://metrics.cocoapods.org/hooks/trunk/#{ENV['OUTGOING_HOOK_PATH']}",
    "http://search.cocoapods.org/hooks/trunk/#{ENV['OUTGOING_HOOK_PATH']}"
  ]

  # Fifo file location.
  #
  def self.fifo
    './tmp/webhook_calls'
  end

  # Set up FIFO file (the "queue").
  #
  `mkfifo #{fifo}` unless File.exist?(fifo)

  # Use in Trunk to notify all attached services.
  #
  # Blocks until message is read.
  # With the below implementation, blocks on average 0.004 s
  # if this method is called 10 times per second on average.
  #
  def self.call(message)
    `echo #{message} > #{fifo}`
  end

  # Used in the worker process to process hook calls.
  #
  # Reads from the fifo queue.
  #
  # This absolutely needs to run in the current design,
  # as the self.call above will block on fifo until it's read.
  #
  def self.run
    # Remember zombie children.
    #
    pids = []
    loop do
      # Block and wait for messages.
      #
      message = `cat #{fifo}`.chomp

      # Clean up old zombie children as soon as our queue is larger than 10.
      #
      Process.wait2(pids.shift, Process::WNOHANG) if pids.size > 10

      # Contact webhooks in a child process.
      #
      command = %Q{curl -s -f -G --data "message=#{message}" --connect-timeout 1 --max-time 1 {#{URLS.join(',')}}}
      pids << fork { exec command }
    end
  end
end
