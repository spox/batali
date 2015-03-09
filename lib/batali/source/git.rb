require 'batali'
require 'fileutils'
require 'tmpdir'

module Batali
  # Source of asset
  class Source
    # Path based source
    class Git < Path

      include Bogo::Memoization

      attribute :path, String
      attribute :url, String, :required => true
      attribute :ref, String, :required => true

      # @return [String] directory containing contents
      def asset
        memoize(:asset) do
          dir = Dir.mktmpdir
          FileUtils.cp_r(path, dir)
          dir
        end
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
