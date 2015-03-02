require 'bogo-cli'
require 'grimoire'

module Batali

  VERSION_CLASS = Grimoire::VERSION_CLASS

  autoload :Command, 'batali/command'
  autoload :Config, 'batali/config'
  autoload :RemoteSite, 'batali/remote_site'
  autoload :Source, 'batali/source'
  autoload :Unit, 'batali/unit'

end

require 'batali/b_file'
require 'batali/version'
