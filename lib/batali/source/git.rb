require 'batali'
require 'fileutils'
require 'tmpdir'

module Batali
  # Source of asset
  class Source
    # Path based source
    class Git < Path

      include Bogo::Memoization
      include Batali::Git

      attribute :path, String

      # @return [String] directory containing contents
      def asset
        clone_repository
        self.path = ref_dup
        super
      end

      # Overload to remove non-relevant attributes
      def to_json(*args)
        MultiJson.dump(
          Smash.new(
            :url => url,
            :ref => ref,
            :type => self.class.name
          ), *args
        )
      end

    end
  end
end
