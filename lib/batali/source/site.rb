require 'batali'
require 'http'
require 'tmpdir'
require 'rubygems/package'
require 'zlib'

module Batali
  class Source
    # Site based source
    class Site < Source

      # @return [Array<Hash>] dependency strings
      attr_reader :dependencies
      # @return [String] version
      attr_reader :version

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

      # @return [String] directory
      def asset
        path = Dir.mktmpdir('batali')
        result = HTTP.get(url)
        while(result.code == 302)
          result = HTTP.get(result.headers['Location'])
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
        path
      end

    end
  end
end
