require 'batali'

module Batali
  class Command

    # Cache management and information
    class Cache < Batali::Command

      # Display information from manifest
      def execute!
        if(opts[:scrub])
          scrub!
        end
        ui.puts ui.color('Batali cache information:', :bold) + "\n"
        display
      end

      # Remove all contents from local cache
      def scrub!
        ui.confirm "Remove all contents from local cache (#{cache_directory})"
        run_action 'Scrubbing local cache' do
          FileUtils.rm_rf(cache_directory)
          nil
        end
      end

      # Display local cache information
      def display
        cache_size = Dir.glob(File.join(cache_directory, '**', '**', '*')).map do |path|
          File.size(path) if File.file?(path)
        end.compact.inject(&:+).to_i
        cache_size = "#{sprintf('%.2f', ((cache_size / 1024.to_f) / 1024))}M"
        [
          "#{ui.color('Path:', :bold)} #{cache_directory}",
          "#{ui.color('Size:', :bold)} #{cache_size}"
        ].each do |line|
          ui.puts "  #{line}"
        end
      end

    end

  end
end
