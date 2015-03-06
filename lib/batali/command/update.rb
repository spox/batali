require 'batali'

module Batali
  class Command

    # Update cookbook manifest
    class Update < Batali::Command

      def execute!
        Resolve.new({:resolve => opts}, arguments).execute!
        Install.new({:install => opts}, arguments).execute!
      end

    end

  end
end
