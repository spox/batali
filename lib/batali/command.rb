require 'batali'
require 'fileutils'

module Batali
  # Customized command base for Batali
  class Command < Bogo::Cli::Command

    DEFAULT_CONFIGURATION_FILES = ['.batali']

    include Bogo::Memoization

    autoload :Configure, 'batali/command/configure'
    autoload :Install, 'batali/command/install'
    autoload :Resolve, 'batali/command/resolve'
    autoload :Update, 'batali/command/update'

    # Set UI when loading via command
    def initialize(*_)
      super
      Batali.ui = ui
    end

    # @return [BFile]
    def batali_file
      memoize(:batali_file) do
        # TODO: Add directory traverse searching
        path = config.fetch(:file, File.join(Dir.pwd, 'Batali'))
        ui.verbose "Loading Batali file from: #{path}"
        bfile = BFile.new(path)
        if(bfile.discover)
          bfile.auto_discover!
        end
        bfile
      end
    end

    # @return [Manifest]
    def manifest
      memoize(:manifest) do
        path = File.join(
          File.dirname(
            config.fetch(:file, File.join(Dir.pwd, 'batali.manifest'))
          ), 'batali.manifest'
        )
        ui.verbose "Loading manifest file from: #{path}"
        Manifest.build(path)
      end
    end

    # @return [String] path to local cache
    def cache_directory(*args)
      memoize(['cache_directory', *args].join('_')) do
        directory = config.fetch(:cache_directory, File.join(Dir.home, '.batali/cache'))
        ui.debug "Cache directory to persist cookbooks: #{directory}"
        unless(args.empty?)
          directory = File.join(directory, *args.map(&:to_s))
        end
        FileUtils.mkdir_p(directory)
        directory
      end
    end

    # Do not execute block if dry run
    #
    # @param action [String] action to be performed
    # @yield block to execute
    def dry_run(action)
      if(config[:dry_run])
        ui.warn "Dry run disabled: #{action}"
      else
        yield
      end
    end

  end
end
