require 'batali'
require 'http'

module Batali
  class Source
    # Site based source
    class Site < Source

      # @return [Array<Hash>] dependency strings
      attr_reader :dependencies
      # @return [String] version
      attr_reader :version

      attribute :url, String, :required => true

      # Extract extra info before allowing super to load data
      #
      # @param args [Hash]
      # @return [self]
      def initialize(args={})
        @version = args.delete(:version)
        unless(version)
          raise ArgumentError.new 'Missing required option `:version`!'
        end
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
      end

    end
  end
end
