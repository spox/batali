require "batali"

module Batali
  class Command

    # Update cookbook manifest
    class Update < Batali::Command
      def execute!
        Resolve.new(config.merge(:ui => ui), arguments).execute!
        if opts[:install]
          Install.new(config.merge(:ui => ui, :install => {}), arguments).execute!
        end
      end
    end
  end
end
