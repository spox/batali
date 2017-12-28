require 'bogo-cli'
require 'grimoire'
require 'batali/monkey'

# Batali namespace
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

  autoload :TAG_LINES, 'batali/tag_lines'

  class << self
    # @return [Bogo::Ui]
    attr_reader :ui

    # Set Ui instance
    #
    # @param ui [Bogo::Ui]
    # @return [Bogo::Ui]
    def ui=(ui)
      unless ui.respond_to?(:verbose) && ui.respond_to?(:debug)
        raise TypeError.new "Expecting type `Bogo::Ui` but received `#{ui.class}`"
      end
      @ui = Grimoire.ui = ui
    end

    # Write verbose message
    def verbose(*args)
      if ui
        ui.verbose(*args)
      end
    end

    # Write debug message
    def debug(*args)
      if ui
        ui.debug(*args)
      end
    end
  end
end

require 'batali/b_file'
require 'batali/version'
