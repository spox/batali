require 'batali'
require 'bogo/http_proxy'

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
