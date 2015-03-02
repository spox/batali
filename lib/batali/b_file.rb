require 'batali'

module Batali

  class Struct < AttributeStruct

    def cookbook(*args)
      set!(:cookbook, args)
      self
    end

  end

  # Create a new file
  #
  # @param block [Proc]
  # @return [AttributeStruct]
  def self.define(&block)
    struct = Struct.new
    struct.set_state!(:value_collapse => true)
    struct.build!(&block)
    struct
  end

  class BFile < Bogo::Config

    class Cookbook < Grimoire::Utility
      attribute :name, String, :required => true
      attribute :constraint, String, :multiple => true
      attribute :git, Smash, :coerce => lambda{|v| v.to_smash}
      attribute :path, String
    end

    attribute :source, RemoteSite, :multiple => true, :coerce => lambda{|v| RemoteSite.new(:endpoint => v)}
    attribute :cookbook, Cookbook, :multiple => true, :coerce => lambda{|v|
      case v
      when Array
        Cookbook.new(
          :name => v.first,
          :constraint => v.slice(1, v.size)
        )
      when String
        Cookbook.new(:name => v)
      when Hash
        c_name = v.keys.first
        constraints = v.values.first.to_a.flatten.find_all{|i| i.is_a?(String)}
        Cookbook.new(
          :name => c_name,
          :constraint => constraints
        )
      else
        raise ArgumentError.new "Unable to coerce given type `#{v.class}` to `Batali::BFile::Cookbook`!"
      end
    }

    ## TODO: supported values still required
    # attribute :restrict -- restrict cookbooks of name `x` to source  named `y`
    # attribute :group -- cookbook grouping (i.e. :integration)
  end

end
