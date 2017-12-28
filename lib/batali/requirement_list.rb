require 'batali'

# Batali namespace
module Batali
  # Customized Unit
  class RequirementList < Grimoire::RequirementList
    attribute(:requirements, [Batali::UnitDependency, Grimoire::DEPENDENCY_CLASS],
              :multiple => true,
              :default => [],
              :coerce => lambda { |v|
                Batali::UnitDependency.new(val.first, *val.last)
              })
  end
end
