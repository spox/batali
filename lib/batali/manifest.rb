require 'batali'

module Batali
  # Collection of resolved units
  class Manifest < Grimoire::Utility

    attribute :cookbook, Unit, :multiple => true

    # Build manifest from given path. If no file exists, empty
    # manifest will be provided.
    #
    # @param path [String] path to manifest
    # @return [Manifest]
    def self.build(path)
      if(File.exists?(path))
        self.new(
          :cookbook => Bogo::Config.new(
            :path => path
          ).data[:cookbook]
        )
      else
        self.new
      end
    end

    # Check for unit within manifest
    #
    # @param unit [Unit]
    # @return [TrueClass, FalseClass]
    def include?(unit)
      cookbook && cookbook.include?(unit)
    end

  end
end
