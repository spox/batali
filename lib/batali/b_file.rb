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

    class Cookbook < Utility
      attribute :name, String, :required => true
      attribute :constraint, String, :multiple => true
      attribute :git, Smash, :coerce => lambda{|v| v.to_smash}
      attribute :path, String
    end

    class Restriction < Utility
      attribute :cookbook, String, :required => true
      attribute :source, String, :required => true
    end

    class Group < Utility
      attribute :name, String, :required => true
      attribute :cookbook, Cookbook, :multiple => true, :required => true, :coerce => BFile.cookbook_coerce
    end

    attribute :restrict, Restriction, :multiple => true, :coerce => lambda{|v| Restriction.new(:cookbook => v.first, :source => v.last)}
    attribute :source, RemoteSite, :multiple => true, :coerce => lambda{|v| RemoteSite.new(:endpoint => v)}
    attribute :group, Group, :multiple => true, :coerce => lambda{|v| Group.new()}
    attribute :cookbook, Cookbook, :multiple => true, :coerce => BFile.cookbook_coerce

    # @return [Proc] cookbook convert
    def self.cookbook_coerce
      proc do |v|
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
      end
    end

  end

end
