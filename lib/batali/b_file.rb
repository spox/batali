require 'batali'

module Batali

  class Struct < AttributeStruct

    def cookbook(*args)
      unless(self[:cookbook])
        set!(:cookbook, ::AttributeStruct::CollapseArray.new.push(args))
      else
        self[:cookbook].push(args)
      end
      self
    end

    def source(*args)
      unless(self[:source])
        set!(:source, ::AttributeStruct::CollapseArray.new.push(args))
      else
        self[:source].push(args)
      end
      self
    end

    def restrict(*args)
      unless(self[:restrict])
        set!(:restrict, ::AttributeStruct::CollapseArray.new.push(args))
      else
        self[:restrict].push(args)
      end
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

    # @return [Proc] cookbook convert
    def self.cookbook_coerce
      proc do |v|
        v = [v].flatten.compact
        name, args = v.first, v.slice(1, v.size)
        if(args.empty?)
          args = Smash.new
        elsif(args.size == 1 && args.first.is_a?(Hash))
          args = args.first
        else
          args = Smash.new(:constraint => args.map(&:to_s))
        end
        Cookbook.new(Smash.new(:name => name).merge(args))
      end
    end

    class Cookbook < Utility
      attribute :name, String, :required => true
      attribute :constraint, String, :multiple => true
      attribute :git, String
      attribute :ref, String
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

    attribute :restrict, Restriction, :multiple => true, :coerce => lambda{|v|
      Restriction.new(:cookbook => v.first, :source => v.last.to_smash[:source])
    }
    attribute :source, Origin::RemoteSite, :multiple => true, :coerce => lambda{|v|
      args = Smash.new(:endpoint => v.first)
      if(v.last.is_a?(Hash))
        args.merge!(v.last)
      end
      Origin::RemoteSite.new(args)
    }
    attribute :group, Group, :multiple => true, :coerce => lambda{|v| Group.new()}
    attribute :cookbook, Cookbook, :multiple => true, :coerce => BFile.cookbook_coerce, :default => []

  end

end
