require 'batali'

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

  end
end
