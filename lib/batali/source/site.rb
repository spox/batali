require "batali"
require "http"
require "tmpdir"
require "rubygems/package"
require "zlib"

module Batali
  class Source
    # Site based source
    class Site < Source
      include Bogo::Memoization

      # @return [Array<Hash>] dependency strings
      attr_reader :dependencies
      # @return [String] version
      attr_reader :version
      # @return [String] local cache path
      attr_accessor :cache

      attribute :url, String, :required => true, :equivalent => true
      attribute :version, String, :required => true, :equivalent => true

      # Extract extra info before allowing super to load data
      #
      # @param args [Hash]
      # @return [self]
      def initialize(args = {})
        @deps = args.delete(:dependencies) || {}
        super
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
          @cache ||= Utility.join_path(cache_path, "remote_site")
          cache
        end
      end

      # @return [String] directory
      def asset
        path = Utility.join_path(cache_directory, Base64.urlsafe_encode64(url))
        if File.directory?(path)
          discovered_path = Dir.glob(Utility.join_path(path, "*")).reject do |i|
            i.end_with?("#{File::SEPARATOR}asset")
          end.first
          FileUtils.rm_rf(path)
        end
        unless discovered_path
          retried = false
          begin
            FileUtils.mkdir_p(path)
            result = HTTP.get(url.end_with?("/") ? url : url + "/")
            while result.code == 302
              result = HTTP.get(result.headers["Location"])
            end
            File.open(a_path = Utility.join_path(path, "asset"), "wb") do |file|
              while content = result.body.readpartial(2048)
                file.write content
              end
            end
            ext = Gem::Package::TarReader.new(
              Zlib::GzipReader.open(a_path)
            )
            ext.rewind
            ext.each do |entry|
              next unless entry.file?
              n_path = Utility.join_path(path, entry.full_name)
              FileUtils.mkdir_p(File.dirname(n_path))
              File.open(n_path, "wb") do |file|
                while content = entry.read(2048)
                  file.write(content)
                end
              end
            end
            begin
              FileUtils.rm(a_path)
            rescue Errno::EACCES
              # windows is dumb some times
            end
          rescue => e
            FileUtils.rm_rf(path)
            unless retried
              FileUtils.mkdir_p(path)
              retried = true
              retry
            end
            raise
          end
          discovered_path = Dir.glob(Utility.join_path(path, "*")).reject do |i|
            i.end_with?("#{File::SEPARATOR}asset")
          end.first
        end
        unless discovered_path
          raise Errno::ENOENT.new "Failed to locate asset within `#{path}`"
        end
        discovered_path
      end

      # @return [TrueClass, FalseClass]
      def clean_asset(asset_path)
        if asset_path
          super File.dirname(asset_path)
        else
          false
        end
      end
    end
  end
end
