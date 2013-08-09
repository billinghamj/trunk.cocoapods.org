require 'rack/ssl'
require 'sinatra/base'

require 'config/init'

# First define the base controller class.
module Pod
  module TrunkApp
    class AppController < Sinatra::Base
      configure do
        set :root, ROOT
      end

      configure :development, :production do
        enable :logging
      end

      use Rack::SSL
    end
  end
end

# Now load subclass controllers.
require 'app/controllers/api_controller'
require 'app/controllers/manage_controller'
require 'app/controllers/travis_notification_controller'

# And assemble base routes to controllers map.
module Pod
  module TrunkApp
    App = Rack::URLMap.new(
      '/api/v1' => APIController,
      '/manage' => ManageController,
      '/travis' => TravisNotificationController
    )
  end
end
