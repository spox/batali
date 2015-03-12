require 'batali'

module Batali
  # Customized Unit
  class Unit < Grimoire::Unit
    attribute :source, Source, :required => true, :coerce => lambda{|v| Batali::Source.build(v)}
    attribute :dependencies, Batali::UnitDependency, :multiple => true, :default => [], :coerce => lambda{|val| Batali::UnitDependency.new(val.first, *val.last)}
    attribute :version, Batali::UnitVersion, :required => true, :coerce => lambda{|val| Batali::UnitVersion.new(val)}
  end
end
