require 'batali'

module Batali

  # Create a new file
  #
  # @param block [Proc]
  # @return [AttributeStruct]
  def self.define(&block)
    struct = AttributeStruct.new
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
        Cookbook.new(v)
      else
        raise ArgumentError.new "Unable to coerce given type `#{v.class}` to `Batali::BFile::Cookbook`!"
      end
    }

    ## TODO: supported values still required
    # attribute :restrict -- restrict cookbooks of name `x` to source  named `y`
    # attribute :group -- cookbook grouping (i.e. :integration)
  end

end
