require 'batali'
require 'digest/sha2'
require 'securerandom'
require 'http'
require 'fileutils'

module Batali
  class Origin
    # Fetch unit information from remote site
    class RemoteSite < Origin

      # Site suffix for API endpoint
      API_SUFFIX = 'api/v1/'

      include Bogo::Memoization

      attribute :name, String
      attribute :identifier, String
      attribute :endpoint, String, :required => true
      attribute :force_update, [TrueClass, FalseClass], :required => true, :default => false
      attribute :update_interval, Integer, :required => true, :default => 60

      def initialize(*_)
        super
        # NOTE: We currently don't require API_SUFFIX information
        # self.endpoint = URI.join(endpoint, API_SUFFIX).to_s
        self.identifier = Digest::SHA256.hexdigest(endpoint)
        unless(name?)
          self.name = identifier
        end
      end

      # @return [String] cache directory path
      def cache_directory
        memoize(:cache_directory) do
          c_path = File.join(cache_path, 'remote_site', identifier)
          FileUtils.mkdir_p(c_path)
          c_path
        end
      end

      # @return [Array<Unit>] all units
      def units
        memoize(:units) do
          items.map do |u_name, versions|
            versions.map do |version, info|
              Unit.new(
                :name => u_name,
                :version => version,
                :dependencies => info[:dependencies].to_a,
                :source => Smash.new(
                  :type => :site,
                  :url => info[:download_url],
                  :version => version,
                  :dependencies => info[:dependencies],
                  :cache_path => cache_path
                )
              )
            end
          end.flatten
        end
      end

      protected

      # @return [Smash] all info
      def items
        memoize(:items) do
          MultiJson.load(File.read(fetch)).to_smash
        end
      end

      # Fetch the universe
      #
      # @return [String] path to universe file
      def fetch
        do_fetch = true
        cache_directory # init directory creation
        if(File.exist?(universe_path))
          age = Time.now - File.mtime(universe_path)
          if(age < update_interval)
            do_fetch = false
          end
        end
        if(do_fetch)
          t_uni = "#{universe_path}.#{SecureRandom.urlsafe_base64}"
          result = HTTP.get(URI.join(endpoint, 'universe'))
          File.open(t_uni, 'w') do |file|
            while(content = result.body.readpartial(2048))
              file.write content
            end
          end
          FileUtils.mv(t_uni, universe_path)
        end
        universe_path
      end

      # @return [String] path to universe file
      def universe_path
        File.join(cache_directory, 'universe.json')
      end

    end
  end
end
