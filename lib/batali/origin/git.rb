require 'git'
require 'batali'

module Batali
  class Origin
    # Fetch unit from local path
    class Git < Path
      include Batali::Git
      attribute :path, String, :required => false
      attribute :subdirectory, String

      def initialize(args = {})
        super
        self.identifier = Smash.new(
          :url => url,
          :ref => ref,
          :subdirectory => subdirectory,
        ).checksum
        unless name?
          self.name = identifier
        end
      end

      # @return [Array<Unit>]
      def units
        memoize(:g_units) do
          items = super
          items.first.source = Source::Git.new(
            :url => url,
            :ref => ref,
            :subdirectory => subdirectory,
            :cache_path => cache_path,
          )
          items
        end
      end

      # @return [Smash] metadata information
      def load_metadata
        fetch_repo
        original_path = path.dup
        self.path = File.join(*[path, subdirectory].compact)
        result = super
        self.path = original_path
        result
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
