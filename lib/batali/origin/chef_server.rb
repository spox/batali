require "batali"
require "digest/sha2"
require "securerandom"
require "http"
require "fileutils"

module Batali
  class Origin
    # Fetch unit information from chef server
    class ChefServer < Origin
      include Bogo::Memoization
      include Utility::Chef

      attribute :name, String
      attribute :identifier, String

      def initialize(*_)
        super
        init_chef!
        self.identifier = Digest::SHA256.hexdigest(endpoint)
        unless name?
          self.name = identifier
        end
      end

      # @return [Array<Unit>] all units
      def units
        memoize(:units) do
          debug "Fetching units from chef server: #{endpoint}"
          units = api_service.get_rest("cookbooks?num_versions=all").map do |c_name, meta|
            meta["versions"].map do |info|
              "#{c_name}/#{info["version"]}"
            end
          end.flatten.map do |ckbk|
            debug "Unit information from #{endpoint}: #{ckbk.inspect}"
            c_name, c_version = ckbk.split("/", 2)
            c_deps = api_service.get_rest(
              "cookbooks/#{c_name}/#{c_version}"
            ).metadata.dependencies.to_a
            Unit.new(
              :name => c_name,
              :version => c_version,
              :dependencies => c_deps,
              :source => Smash.new(
                :type => :chef_server,
                :version => c_version,
                :dependencies => c_deps,
                :endpoint => endpoint,
                :client_key => client_key,
                :client_name => client_name,
                :cache_path => cache_path,
              ),
            )
          end.flatten
        end
      end
    end
  end
end
