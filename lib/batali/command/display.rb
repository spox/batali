require "batali"

module Batali
  class Command

    # Display manifest information
    class Display < Batali::Command

      # Display information from manifest
      def execute!
        ui.puts ui.color("Batali manifest information:", :bold) + "\n"
        display(arguments)
      end

      # Display manifest information
      #
      # @param names [Array<String>] limit to given cookbooks
      # @return [NilClass]
      def display(ckbk_names)
        info = Smash.new.tap do |ckbks|
          manifest.cookbook.sort_by(&:name).each do |ckbk|
            ckbks[ckbk.name] ||= []
            ckbks[ckbk.name].push(ckbk)
          end
        end
        info.each do |name, ckbks|
          next unless ckbk_names.empty? || ckbk_names.include?(name)
          ui.puts "  #{ui.color(name, :bold)}:"
          ckbks.each do |ckbk|
            ui.puts "    Version: #{ckbk.version}"
            case ckbk.source
            when Batali::Source::Site
              ui.puts "    Source: #{URI.parse(ckbk.source.url).host}"
            when Batali::Source::Git
              ui.puts "    Source: #{ckbk.source.url}"
              ui.puts "    Reference: #{ckbk.source.ref}"
            when Batali::Source::Path
              ui.puts "    Source: #{ckbk.source.path}"
            end
          end
        end
      end
    end
  end
end
