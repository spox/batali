require 'batali'

# Batali namespace
module Batali
  # Customized Unit
  class Unit < Grimoire::Unit
    attribute :source, Source, :coerce => lambda{|v| Batali::Source.build(v)}
    attribute(:dependencies, [Batali::UnitDependency, Grimoire::DEPENDENCY_CLASS],
      :multiple => true,
      :default => [],
      :coerce => lambda{ |val|
        Batali::UnitDependency.new(val.first, *val.last)
      }
    )
    attribute(:version, [Batali::UnitVersion, Grimoire::VERSION_CLASS],
      :required => true,
      :coerce => lambda{ |val|
        Batali::UnitVersion.new(val)
      }
    )

    # @return [TrueClass, FalseClass]
    def diff?(u)
      !same?(u)
    end

    # @return [TrueClass, FalseClass]
    def same?(u)
      diff(u).empty?
    end

    # @return [String] difference output
    def diff(u)
      Smash.new.tap do |_diff|
        [:name, :version].each do |k|
          unless(send(k) == u.send(k))
            _diff[k] = [send(k), u.send(k)]
          end
        end
        if(source)
          _diff.merge!(source.diff(u.source))
        end
      end
    end

  end
end
