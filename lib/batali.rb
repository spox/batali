require 'bogo-cli'
require 'grimoire'
require 'batali/monkey'

module Batali

  autoload :BFile, 'batali/b_file'
  autoload :Command, 'batali/command'
  autoload :Config, 'batali/config'
  autoload :Git, 'batali/git'
  autoload :Manifest, 'batali/manifest'
  autoload :Origin, 'batali/origin'
  autoload :RequirementList, 'batali/requirement_list'
  autoload :ScoreKeeper, 'batali/score_keeper'
  autoload :Source, 'batali/source'
  autoload :Struct, 'batali/b_file'
  autoload :Unit, 'batali/unit'
  autoload :UnitLoader, 'batali/unit_loader'
  autoload :Utility, 'batali/utility'

end

require 'batali/b_file'
require 'batali/version'
