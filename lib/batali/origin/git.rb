require 'git'
require 'batali'

module Batali
  class Origin
    # Fetch unit from local path
    class Git < Path

      include Batali::Git

      def initialize(args={})
        unless(args[:path])
          args[:path] = '/dev/null'
        end
        super
        self.identifier = Smash.new(
          :url => url,
          :ref => ref
        ).checksum
        unless(name?)
          self.name = self.identifier
        end
      end

      # @return [Array<Unit>]
      def units
        memoize(:g_units) do
          items = super
          items.first.source = Source::Git.new(
            :url => url,
            :ref => ref,
            :path => path
          )
          items
        end
      end

      # @return [Smash] metadata information
      def load_metadata
        fetch_repo
        super
      end

      # @return [String] path to repository
      def fetch_repo
        memoize(:fetch_repo) do
          clone_repository
          ref_dup
        end
      end

    end
  end
end
