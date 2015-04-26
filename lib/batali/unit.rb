require 'batali'

module Batali
  # Customized Unit
  class Unit < Grimoire::Unit
    attribute :source, Source, :coerce => lambda{|v| Batali::Source.build(v)}
    attribute :dependencies, [Batali::UnitDependency, Grimoire::DEPENDENCY_CLASS], :multiple => true, :default => [], :coerce => lambda{|val| Batali::UnitDependency.new(val.first, *val.last)}
    attribute :version, [Batali::UnitVersion, Grimoire::VERSION_CLASS], :required => true, :coerce => lambda{|val| Batali::UnitVersion.new(val)}
  end
end
