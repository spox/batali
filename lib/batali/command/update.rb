require 'batali'

module Batali
  class Command

    # Update cookbook manifest
    class Update < Batali::Command

      def execute!
        Resolve.new(opts.merge(:ui => ui), arguments).execute!
        Install.new(opts.merge(:ui => ui, :install => {}), arguments).execute!
      end

    end

  end
end
