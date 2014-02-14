require 'app/models/commit'
require 'app/concerns/git_commit_sha_validator'

module Pod
  module TrunkApp
    class PodVersion < Sequel::Model
      include Concerns::GitCommitSHAValidator

      DATA_URL = "https://raw.github.com/#{ENV['GH_REPO']}/%s/%s"

      self.dataset = :pod_versions

      plugin :timestamps
      plugin :validation_helpers
      plugin :after_initialize

      many_to_one :pod
      one_to_many :commits, :order => Sequel.asc([:updated_at, :created_at])
      
      def published?
        commits.any?(&:pushed?)
      end
      
      def published_by
        commits.select(&:pushed?)
      end
      
      def last_published_by
        published_by.last
      end
      
      def commit_sha
        last_published_by.sha
      end

      def after_initialize
        super
        # if new?
        #   self.published = false if published.nil?
        # end
      end

      def public_attributes
        { 'created_at' => created_at, 'name' => name }
      end

      def destination_path
        File.join('Specs', pod.name, name, "#{pod.name}.podspec.json")
      end
      
      def message
        "[Add] #{pod.name} #{name}"
      end

      def data_url
        DATA_URL % [commit_sha, destination_path] if commit_sha
      end

      def resource_path
        URI.escape("/pods/#{pod.name}/versions/#{name}")
      end

      protected

      UNIQUE_VERSION = [:pod_id, :name]

      def validate
        super
        validates_presence :pod_id
        validates_presence :name
        # validates_presence :published
        # validates_git_commit_sha :commit_sha

        validates_unique UNIQUE_VERSION
        # Sequel adds the error with the column tuple as the key, but for the
        # user just uing `name' as the key is more semantic.
        if error = errors.delete(UNIQUE_VERSION)
          errors.add(:name, error.first)
        end
      end
    end
  end
end
