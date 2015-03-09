require 'bogo-cli'
require 'grimoire'

module Batali

  autoload :Command, 'batali/command'
  autoload :Config, 'batali/config'
  autoload :Git, 'batali/git'
  autoload :Manifest, 'batali/manifest'
  autoload :Origin, 'batali/origin'
  autoload :ScoreKeeper, 'batali/score_keeper'
  autoload :Source, 'batali/source'
  autoload :Unit, 'batali/unit'
  autoload :UnitLoader, 'batali/unit_loader'
  autoload :Utility, 'batali/utility'

end

require 'batali/b_file'
require 'batali/monkey'
require 'batali/version'
