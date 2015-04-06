require 'batali'
require 'http'
require 'tmpdir'
require 'rubygems/package'
require 'zlib'

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

      attribute :url, String, :required => true
      attribute :version, String, :required => true

      # Extract extra info before allowing super to load data
      #
      # @param args [Hash]
      # @return [self]
      def initialize(args={})
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
          unless(@cache)
            @cache = File.expand_path('~/.batali/cache/remote_site')
          end
          ['entitystore', 'metastore'].each do |leaf|
            FileUtils.mkdir_p(File.join(cache, leaf))
          end
          cache
        end
      end

      # @return [String] directory
      def asset
        path = File.join(cache_directory, Base64.urlsafe_encode64(url))
        unless(File.directory?(path))
          FileUtils.mkdir_p(path)
          result = HTTP.with_cache(
            :metastore => "file:#{File.join(cache_directory, 'metastore')}",
            :entitystore => "file:#{File.join(cache_directory, 'entitystore')}"
          ).get(url)
          while(result.code == 302)
            result = HTTP.with_cache(
              :metastore => "file:#{File.join(cache_directory, 'metastore')}",
              :entitystore => "file:#{File.join(cache_directory, 'entitystore')}"
            ).get(result.headers['Location'])
          end
          File.open(a_path = File.join(path, 'asset'), 'w') do |file|
            while(content = result.body.readpartial(2048))
              file.write content
            end
          end
          ext = Gem::Package::TarReader.new(
            Zlib::GzipReader.open(a_path)
          )
          ext.rewind
          ext.each do |entry|
            next unless entry.file?
            n_path = File.join(path, entry.full_name)
            FileUtils.mkdir_p(File.dirname(n_path))
            File.open(n_path, 'w') do |file|
              while(content = entry.read(2048))
                file.write(content)
              end
            end
          end
          FileUtils.rm(a_path)
        end
        Dir.glob(File.join(path, '*')).first
      end

      # @return [TrueClass, FalseClass]
      def clean_asset(asset_path)
        super File.dirname(asset_path)
      end

    end
  end
end
