require 'batali'
require 'fileutils'

module Batali
  # Customized command base for Batali
  class Command < Bogo::Cli::Command

    include Bogo::Memoization

    autoload :Configure, 'batali/command/configure'
    autoload :Install, 'batali/command/install'
    autoload :Resolve, 'batali/command/resolve'
    autoload :Update, 'batali/command/update'

    # @return [BFile]
    def batali_file
      memoize(:batali_file) do
        # TODO: Add directory traverse searching
        BFile.new(opts.fetch(:file, File.join(Dir.pwd, 'Batali')))
      end
    end

    # @return [Manifest]
    def manifest
      memoize(:manifest) do
        Manifest.build(
          File.join(
            File.dirname(
              opts.fetch(:file, File.join(Dir.pwd, 'batali.manifest'))
            ), 'batali.manifest'
          )
        )
      end
    end

    # @return [String] path to local cache
    def cache_directory(*args)
      memoize(:cache_directory) do
        directory = opts.fetch(:cache_directory, '/tmp/batali-cache')
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
      if(opts[:dry_run])
        ui.warn "Dry run disabled: #{action}"
      else
        yield
      end
    end

  end
end
