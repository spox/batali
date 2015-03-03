require 'bogo-cli'
require 'grimoire'

module Batali

  # Simple stubs mostly for naming
  class UnitVersion < Grimoire::VERSION_CLASS; end
  class UnitDependency < Grimoire::DEPENDENCY_CLASS; end
  class UnitRequirement < Grimoire::REQUIREMENT_CLASS; end

  autoload :Command, 'batali/command'
  autoload :Config, 'batali/config'
  autoload :Manifest, 'batali/manifest'
  autoload :RemoteSite, 'batali/remote_site'
  autoload :ScoreKeeper, 'batali/score_keeper'
  autoload :Source, 'batali/source'
  autoload :Unit, 'batali/unit'

end

require 'batali/b_file'
require 'batali/version'

Grimoire.send(:remove_const, :VERSION_CLASS)
Grimoire.send(:remove_const, :DEPENDENCY_CLASS)
Grimoire.send(:remove_const, :REQUIREMENT_CLASS)

Grimoire.const_set(:VERSION_CLASS, Batali::UnitVersion)
Grimoire.const_set(:DEPENDENCY_CLASS, Batali::UnitDependency)
Grimoire.const_set(:REQUIREMENT_CLASS, Batali::UnitRequirement)
