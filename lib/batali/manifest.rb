require 'batali'

module Batali
  # Collection of resolved units
  class Manifest < Utility

    include Bogo::Memoization

    attribute :path, String
    attribute :cookbook, Batali::Unit, :multiple => true, :coerce => lambda{|v| Batali::Unit.new(v)}, :default => []

    # Build manifest from given path. If no file exists, empty
    # manifest will be provided.
    #
    # @param path [String] path to manifest
    # @return [Manifest]
    def self.build(path)
      if(File.exists?(path))
        self.new(Bogo::Config.new(path).data.merge(:path => path))
      else
        self.new(:path => path)
      end
    end

    # Check for unit within manifest
    #
    # @param unit [Unit]
    # @return [TrueClass, FalseClass]
    def include?(unit)
      memoize(unit.inspect) do
        if(cookbook)
          !!cookbook.detect do |ckbk|
            ckbk.name == unit.name &&
              ckbk.version == unit.version
          end
        else
          false
        end
      end
    end

  end
end
