require 'batali'

module Batali
  # Customized command base for Batali
  class Command < Bogo::Cli::Command

    autoload :Configure, 'batali/command/configure'
    autoload :Install, 'batali/command/install'
    autoload :Resolve, 'batali/command/resolve'
    autoload :Update, 'batali/command/update'

  end
end
