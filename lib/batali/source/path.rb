require 'batali'
require 'fileutils'
require 'tmpdir'

module Batali
  # Source of asset
  class Source
    # Path based source
    class Path < Source

      include Bogo::Memoization

      attribute :path, String, :required => true

      # @return [String] directory containing contents
      def asset
        memoize(:asset) do
          dir = Dir.mktmpdir
          FileUtils.cp_r(path, dir)
          dir
        end
      end

    end
  end
end
