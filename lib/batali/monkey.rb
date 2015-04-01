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

require 'http/request'

class HTTP::Request

  def proxy
    if(_proxy_point = ENV["#{uri.scheme}_proxy"])
      _proxy = URI.parse(_proxy_point)
      Hash.new.tap do |opts|
        opts[:proxy_address] = _proxy.host
        opts[:proxy_port] = _proxy.port
        opts[:proxy_username] = _proxy.user if _proxy.user
        opts[:proxy_password] = _proxy.password if _proxy.password
      end
    else
      @proxy
    end
  end

end
