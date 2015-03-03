require 'bogo-cli'
require 'grimoire'

module Batali

  autoload :Command, 'batali/command'
  autoload :Config, 'batali/config'
  autoload :Manifest, 'batali/manifest'
  autoload :RemoteSite, 'batali/remote_site'
  autoload :ScoreKeeper, 'batali/score_keeper'
  autoload :Source, 'batali/source'
  autoload :Unit, 'batali/unit'

end

require 'batali/b_file'
require 'batali/monkey'
require 'batali/version'
