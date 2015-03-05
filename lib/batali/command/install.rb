require 'batali'
require 'fileutils'

module Batali
  class Command

    # Install cookbooks based on manifest
    class Install < Batali::Command

      # Install cookbooks
      def execute!
        dry_run('Cookbook installation') do
          run_action('Installing cookbooks') do
            install_path = opts.fetch(:path, 'cookbooks')
            FileUtils.mkdir_p(install_path)
            manifest.cookbook.each do |unit|
              asset_path = unit.source.asset
              begin
                FileUtils.mv(
                  File.join(
                    asset_path,
                    unit.name
                  ),
                  File.join(
                    install_path,
                    unit.name
                  )
                )
              ensure
                FileUtils.rm_rf(asset_path)
              end
            end
            nil
          end
        end
      end

    end

  end
end
