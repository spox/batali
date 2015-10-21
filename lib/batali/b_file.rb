require 'batali'
require 'pathname'

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

    def chef_server(*args)
      unless(self[:chef_server])
        set!(:chef_server, ::AttributeStruct::CollapseArray.new.push(args))
      else
        self[:chef_server].push(args)
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

    def metadata(*args)
      set!(:metadata, *(args.empty? ? [true] : args))
    end

    def _dump(*_)
      _keys.each do |k|
        if(_data[k].nil? && _data[k].is_a?(::AttributeStruct))
          _data[k] = true
        end
      end
      super
    end

    ::Object.constants.each do |const_name|
      const_set(const_name, ::Object.const_get(const_name))
    end

    def require(*args)
      result = ::Kernel.require(*args)
      instance_exec do
        class << self
          ::Object.constants.each do |const_name|
            const_set(const_name, ::Object.const_get(const_name))
          end
        end
      end
      result
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

    attribute :discover, [TrueClass, FalseClass], :required => true, :default => false
    attribute :restrict, Restriction, :multiple => true, :coerce => lambda{|v|
      Restriction.new(:cookbook => v.first, :source => v.last.to_smash[:source])
    }
    attribute :source, Origin::RemoteSite, :multiple => true, :default => [], :coerce => lambda{|v|
      args = Smash.new(:endpoint => v.first)
      if(v.last.is_a?(Hash))
        args.merge!(v.last)
      end
      Origin::RemoteSite.new(args)
    }
    attribute :chef_server, Origin::ChefServer, :multiple => true, :default => [], :coerce => lambda{|v|
      args = Smash.new(:endpoint => v.first)
      if(v.last.is_a?(Hash))
        args.merge!(v.last)
      end
      Origin::ChefServer.new(args)
    }
    attribute :group, Group, :multiple => true, :coerce => lambda{|v| Group.new()}
    attribute :cookbook, Cookbook, :multiple => true, :coerce => BFile.cookbook_coerce, :default => []
    attribute :metadata, Cookbook, :coerce => lambda{ |v, b_file|
      dir = Pathname.new(File.dirname(b_file.path)).relative_path_from(Pathname.new(Dir.pwd)).to_path
      m_unit = Origin::Path.new(:name => 'metadata', :path => dir).units.first
      ckbk = Cookbook.new(:name => m_unit.name, :version => m_unit.version, :path => dir)
      unless(b_file.cookbook.map(&:name).include?(ckbk.name))
        b_file.cookbook.push ckbk
      end
      ckbk
    }

    # Search environments for cookbooks and restraints
    #
    # @return [TrueClass]
    def auto_discover!(environment=nil)
      debug 'Starting cookbook auto-discovery'
      unless(discover)
        raise 'Attempting to perform auto-discovery but auto-discovery is not enabled!'
      end
      environment_items = Dir.glob(File.join(File.dirname(path), 'environments', '*.{json,rb}')).map do |e_path|
        result = parse_environment(e_path)
        if(result[:name] && result[:cookbooks])
          Smash.new(
            result[:name] => result[:cookbooks]
          )
        end
      end.compact.inject(Smash.new){|m,n| m.merge(n)}
      environment_items.each do |e_name, items|
        next if environment && e_name != environment
        debug "Discovery processing of environment: #{e_name}"
        items.each do |ckbk_name, constraints|
          ckbk = cookbook.detect do |c|
            c.name == ckbk_name
          end
          if(ckbk)
            unless(ckbk.constraint)
              debug "Skipping constraint merging due to lack of original constraints: #{ckbk.inspect}"
              next
            end
            new_constraints = ckbk.constraint.dup
            new_constraints += constraints
            requirement = UnitRequirement.new(*new_constraints)
            new_constraints = flatten_constraints(requirement.requirements)
            debug "Discovery merged constraints for #{ckbk.name}: #{new_constraints.inspect}"
            ckbk.constraint.replace(new_constraints)
          else
            debug "Discovery added cookbook #{ckbk_name}: #{constraints.inspect}"
            cookbook.push(
              Cookbook.new(
                :name => ckbk_name,
                :constraint => constraints
              )
            )
          end
        end
      end
      debug 'Completed cookbook auto-discovery'
      true
    end

    protected

    # Convert constraint for merging
    #
    # @param constraint [String]
    # @param [Array<String>]
    def convert_constraint(constraint)
      comp, ver = constraint.split(' ', 2).map(&:strip)
      if(comp == '~>')
        ver = UnitVersion.new(ver)
        [">= #{ver}", "< #{ver.bump}"]
      else
        [constraint]
      end
    end

    # Consume list of constraints and generate compressed list that
    # satisfies all defined constraints.
    #
    # @param constraints [Array<Array<String, UnitVersion>>]
    # @return [Array<Array<String, UnitVersion>>]
    # @note if an explict constraint is provided, only it will be
    # returned
    def flatten_constraints(constraints)
      grouped = constraints.group_by(&:first)
      grouped = Smash[
        grouped.map do |comp, items|
          versions = items.map(&:last)
          if(comp.start_with?('>'))
            [comp, [versions.min]]
          elsif(comp.start_with?('<'))
            [comp, [versions.max]]
          else
            [comp, versions]
          end
        end
      ]
      if(grouped['='])
        grouped['>='] ||= []
        grouped['<='] ||= []
        grouped['='].each do |ver|
          grouped['>='] << ver
          grouped['<='] << ver
        end
        grouped.delete('=')
      end
      if(grouped['>'] || grouped['>='])
        if(grouped['>='] && (grouped['>'].nil? || grouped['>='].min <= grouped['>'].min))
          grouped['>='] = [grouped['>='].min]
          grouped.delete('>')
        else
          grouped['>'] = [grouped['>'].min]
          grouped.delete('>=')
        end
      end
      if(grouped['<'] || grouped['<='])
        if(grouped['<='] && (grouped['<'].nil? || grouped['<='].max >= grouped['<'].max))
          grouped['<='] = [grouped['<='].max]
          grouped.delete('<')
        else
          grouped['<'] = [grouped['<'].max]
          grouped.delete('<=')
        end
      end
      grouped.map do |comp, vers|
        vers.map do |version|
          "#{comp} #{version}"
        end
      end.flatten
    end

    # Read environment file and return defined cookbook constraints
    #
    # @param path [String] path to environment
    # @return [Smash]
    def parse_environment(path)
      case File.extname(path)
      when '.json'
        env = MultiJson.load(
          File.read(path)
        ).to_smash
      when '.rb'
        struct = Struct.new
        struct.set_state!(:value_collapse => true)
        struct.instance_eval(File.read(path), path, 1)
        env = struct._dump.to_smash
      else
        raise "Unexpected file format encountered! (#{File.extname(path)})"
      end
      Smash.new(
        :name => env[:name],
        :cookbooks => Smash[
          env.fetch(
            :cookbook_versions,
            Smash.new
          ).map{|k,v| [k, v.to_s.split(',')]}
        ]
      )
    end

    # Proxy debug output
    def debug(s)
      Batali.debug(s)
    end

  end

end
