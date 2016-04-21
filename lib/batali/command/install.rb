require 'batali'
require 'fileutils'

module Batali
  class Command

    # Install cookbooks based on manifest
    class Install < Batali::Command

      # Install cookbooks
      def execute!
        dry_run('Cookbook installation') do
          install_path = config.fetch(:path, 'cookbooks')
          run_action('Readying installation destination') do
            FileUtils.rm_rf(install_path)
            FileUtils.mkdir_p(install_path)
            nil
          end
          if(manifest.cookbook.nil? || manifest.cookbook.empty?)
            ui.error 'No cookbooks defined within manifest! Try resolving first. (`batali resolve`)'
          else
            run_action('Installing cookbooks') do
              manifest.cookbook.each_slice(100) do |units_slice|
                units_slice.map do |unit|
                  Thread.new do
                    ui.debug "Starting unit install for: #{unit.name}<#{unit.version}>"
                    if(unit.source.respond_to?(:cache_path))
                      unit.source.cache_path = cache_directory(
                        Bogo::Utility.snake(unit.source.class.name.split('::').last)
                      )
                    end
                    asset_path = unit.source.asset
                    final_path = File.join(install_path, unit.name)
                    if(infrastructure?)
                      final_path << "-#{unit.version}"
                    end
                    begin
                      FileUtils.cp_r(
                        File.join(asset_path, '.'),
                        final_path
                      )
                      ui.debug "Completed unit install for: #{unit.name}<#{unit.version}>"
                    rescue => e
                      ui.debug "Failed unit install for: #{unit.name}<#{unit.version}> - #{e.class}: #{e}"
                      raise
                    ensure
                      unit.source.clean_asset(asset_path)
                    end
                  end
                end.map(&:join)
              end
              nil
            end
          end
        end
      end

    end

  end
end
