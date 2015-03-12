require 'batali'

module Batali
  # Customized Unit
  class RequirementList < Grimoire::RequirementList
    attribute :requirements, Batali::UnitDependency, :multiple => true, :default => [], :coerce => lambda{|v| Batali::UnitDependency.new(val.first, *val.last)}
  end
end
