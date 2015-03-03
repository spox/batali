require 'batali'

module Batali
  # Simple stubs mostly for naming
  class UnitVersion < Grimoire::VERSION_CLASS; end
  class UnitRequirement < Grimoire::REQUIREMENT_CLASS; end
  class UnitDependency < Grimoire::DEPENDENCY_CLASS
    def to_json(*args)
      result = [
        name,
        *requirement.requirements.map do |req|
          req.join(' ')
        end
      ]
      MultiJson.dump(result, *args)
    end
  end
end

Grimoire.send(:remove_const, :VERSION_CLASS)
Grimoire.send(:remove_const, :DEPENDENCY_CLASS)
Grimoire.send(:remove_const, :REQUIREMENT_CLASS)

Grimoire.const_set(:VERSION_CLASS, Batali::UnitVersion)
Grimoire.const_set(:DEPENDENCY_CLASS, Batali::UnitDependency)
Grimoire.const_set(:REQUIREMENT_CLASS, Batali::UnitRequirement)
