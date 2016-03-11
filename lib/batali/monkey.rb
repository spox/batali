require 'bogo/http_proxy'

# Batali namespace
module Batali
  # Custom named unit version
  class UnitVersion < Grimoire::VERSION_CLASS; end
  # Custom named unit requirement
  class UnitRequirement < Grimoire::REQUIREMENT_CLASS; end
  # Custom named unit dependency
  class UnitDependency < Grimoire::DEPENDENCY_CLASS
    # Override to properly convert to JSON
    def to_json(*args)
      result = [
        name,
        *requirement.requirements.map do |req|
          req.join(' ')
        end
      ]
      # Prevent stupid conversion errors of
      # JSON::Ext::Generator::State into Hash
      args.map!{|v| v.respond_to?(:to_h) ? v.to_h : v}
      MultiJson.dump(result, *args)
    end
  end
end
