require 'batali'

module Batali
  # Collection of resolved units
  class Manifest < Grimoire::Utility

    attribute :cookbook, Unit, :multiple => true, :required => true

    # Check for unit within manifest
    #
    # @param unit [Unit]
    # @return [TrueClass, FalseClass]
    def include?(unit)
      cookbook.include?(unit)
    end

  end
end
