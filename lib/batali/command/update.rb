require 'batali'

module Batali
  class Command

    # Update cookbook manifest
    class Update < Batali::Command

      def execute!
        Resolve.new(options.merge(:ui => ui), arguments).execute!
        Install.new(options.merge(:ui => ui), arguments).execute!
      end

    end

  end
end
