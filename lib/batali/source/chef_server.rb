require 'batali'
require 'tmpdir'

module Batali
  class Source
    # Chef Server based source
    class ChefServer < Source
      include Bogo::Memoization
      include Utility::Chef

      # @return [Array<Hash>] dependency strings
      attr_reader :dependencies
      # @return [String] local cache path
      attr_accessor :cache
      # @return [string] unique identifier
      attr_reader :identifier

      attribute :version, String, :required => true, :equivalent => true

      # Extract extra info before allowing super to load data
      #
      # @param args [Hash]
      # @return [self]
      def initialize(args = {})
        @deps = args.delete(:dependencies) || {}
        super
        init_chef!
      end

      # @return [Chef::Rest]
      def api_service
        memoize(:api_service) do
          Chef::Rest.new(endpoint)
        end
      end

      # @return [String]
      def unit_version
        version
      end

      # @return [Array<Array<name, constraints>>]
      def unit_dependencies
        deps.to_a
      end

      # @return [String] path to cache
      def cache_directory
        memoize(:cache_directory) do
          @cache ||= File.join(cache_path, 'chef_server', endpoint)
          cache
        end
      end

      # @return [String] directory
      def asset
        path = File.join(cache_directory, name, version)
        begin
          FileUtils.mkdir_p(path)
          cookbook = rest.get_rest("cookbooks/#{name}/#{version}")
          manifest = cookbook.manifest
          Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segement|
            if manifest.key?(segment)
              manifest[segement].each do |s_file|
                new_path = File.join(path, s_file['path'].gsub('/', File::SEPARATOR))
                FileUtils.mkdir_p(File.dirname(new_path))
                api_service.sign_on_redirect = false
                t_file = api_service.get_rest(s_file['url'], true)
                FilUtils.mv(t_file.path, new_path)
              end
            end
          end
        rescue => e
          debug "Failed to fully download cookbook [#{name}<#{version}>] - #{e.class}: #{e}"
          FileUtils.rm_rf(path)
          raise
        end
        path
      end
    end
  end
end
