require 'batali'

class Chef
  class Knife
    class BataliSync < Knife

      banner 'knife batali sync'

      option(:blacklist,
        :short => '-B COOKBOOK_NAME[,COOKBOOK_NAME]',
        :long => '--blacklist COOKBOOK_NAME[,COOKBOOK_NAME]',
        :description => 'Cookbooks to ignore from sync',
        :proc => lambda{|val|
          Chef::Config[:knife][:batali_blacklist] ||= []
          Chef::Config[:knife][:batali_blacklist] += val.split(',')
        }
      )

      option(:details,
        :long => '--[no-]details',
        :boolean => true,
        :default => true,
        :description => 'Show details of cookbooks to be removed / added'
      )

      option(:show_remaining,
        :long => '--[no-]show-remaining',
        :description => 'Display cookbook details of expected final server state',
        :boolean => true,
        :default => false,
        :proc => lambda{|val|
          Chef::Config[:knife][:batali_show_remaining] = val
        }
      )

      option(:dry_run,
        :long => '--[no-]dry-run',
        :description => 'Display information but perform no action',
        :boolean => true,
        :default => false
      )

      def run
        Chef::Config[:knife][:batali_blacklist] ||= []
        config[:verbose] = config[:verbosity].to_i > 0
        ui.info "#{ui.color('[Batali]', :green, :bold)}: Chef Server Batali Manifest Sync"
        valid_cookbooks = run_task('Generating valid cookbook versions from manifest') do
          generate_manifest_cookbooks
        end
        remote_cookbooks = run_task('Generating remote cookbook versions from chef server') do
          generate_remote_cookbooks
        end
        to_remove = run_task('Building cookbook removal list') do
          locate_removals(
            :manifest => valid_cookbooks,
            :server => remote_cookbooks
          )
        end
        to_add = run_task('Building cookbook upload list') do
          locate_additions(
            :manifest => valid_cookbooks,
            :server => remote_cookbooks
          )
        end
        if(to_add.empty? && to_remove.empty?)
          ui.info "#{ui.color('[Batali]', :green, :bold)}: Chef Server Batali Manifest Sync - #{ui.color('No Changes Detected!', :green, :bold)}"
        else
          display_sync_info(
            :additions => to_add,
            :removals => to_remove,
            :manifest => valid_cookbooks
          )
          unless(config[:dry_run])
            ui.confirm 'Sync remote cookbooks with Batali manifest'
            remove_cookbooks(to_remove) unless to_remove.empty?
            add_cookbooks(to_add) unless to_add.empty?
            ui.info "#{ui.color('[Batali]', :green, :bold)}: Chef Server Batali Manifest Sync - #{ui.color('Sync Complete!', :green, :bold)}"
          else
            ui.warn 'Dry run requested. No action taken.'
          end
        end
      end

      def remove_cookbooks(ckbks)
        run_task('Removing cookbooks') do
          ckbks.each do |c_name, vers|
            vers.each do |version|
              if(config[:verbose])
                ui.warn "Deleting cookbook #{c_name} @ #{version}"
              end
              rest.delete("/cookbooks/#{c_name}/#{version}")
            end
          end
        end
      end

      def add_cookbooks(ckbks)
        Batali::Command::Install.new({}, []).execute!
        ui.info "#{ui.color('[Batali]', :green, :bold)}: Adding cookbooks to Chef server."
        Knife::Upload.load_deps
        ckbks.each do |c_name, vers|
          vers.each do |version|
            c_path = [
              File.join('cookbooks', c_name),
              File.join('cookbooks', "#{c_name}-#{version}")
            ].detect do |_path|
              File.directory?(_path)
            end
            uploader = Knife::Upload.new
            uploader.configure_chef
            uploader.config = config
            uploader.name_args = [c_path]
            if(config[:verbose])
              ui.warn "Unloading cookbook #{c_name} @ #{version} - `#{c_path}`"
            end
            uploader.run
          end
        end
        ui.info "#{ui.color('[Batali]', :green, :bold)}: Chef server cookbook additions complete."
      end

      def display_sync_info(opts)
        num_remove = ui.color(opts[:removals].size.to_s, :red, :bold)
        num_add = ui.color(opts[:additions].size.to_s, :green, :bold)
        ui.info "#{ui.color('[Batali]', :green, :bold)}: Removals - #{num_remove} Additions: #{num_add}"
        if(config[:details])
          unless(opts[:removals].empty?)
            ui.info "#{ui.color('[Batali]', :green, :bold)}: Cookbooks to be #{ui.color('removed', :red, :bold)}:"
            opts[:removals].sort.each do |name, versions|
              vers = versions.map do |v|
                Gem::Version.new(v)
              end.sort.map(&:to_s).join(', ')
              ui.info "  #{ui.color(name, :red, :bold)}: #{ui.color(vers, :red)}"
            end
          end
          unless(opts[:additions].empty?)
            ui.info "#{ui.color('[Batali]', :green, :bold)}: Cookbooks to be #{ui.color('added', :green, :bold)}:"
            opts[:additions].sort.each do |name, versions|
              vers = versions.map do |v|
                Gem::Version.new(v)
              end.sort.map(&:to_s).join(', ')
              ui.info "  #{ui.color(name, :green, :bold)}: #{ui.color(vers, :green)}"
            end
          end
          if(Chef::Config[:knife][:batali_show_remaining])
            ui.info "#{ui.color('[Batali]', :green, :bold)}: Final list of cookbooks to be available on the chef server:"
            opts[:manifest].sort.each do |name, versions|
              vers = versions.map do |v|
                Gem::Version.new(v)
              end.sort.map(&:to_s).join(', ')
              ui.info "  #{ui.color(name, :bold)}: #{vers}"
            end
          end
        end
      end

      def locate_removals(opts)
        Smash.new.tap do |rm|
          opts[:server].each do |c_name, c_versions|
            kills = c_versions - opts[:manifest].fetch(c_name, [])
            unless(kills.empty?)
              rm[c_name] = kills
            end
          end
        end
      end

      def locate_additions(opts)
        Smash.new.tap do |add|
          opts[:manifest].each do |c_name, c_versions|
            adds = c_versions - opts[:server].fetch(c_name, [])
            unless(adds.empty?)
              add[c_name] = adds
            end
          end
        end
      end

      def generate_manifest_cookbooks
        path = File.join(Dir.pwd, 'batali.manifest')
        unless(File.exists?(path))
          raise "Failed to locate batali manifest at: #{path}"
        end
        manifest = Batali::Manifest.build(path)
        Smash.new.tap do |ckbks|
          manifest.cookbook.each do |c|
            next if Chef::Config[:knife][:batali_blacklist].include?(c.name)
            ckbks[c.name] ||= []
            ckbks[c.name] << c.version.to_s
          end
        end
      end

      def generate_remote_cookbooks
        Smash.new.tap do |ckbks|
          rest.get('cookbooks?num_versions=all').map do |c_name, meta|
            next if Chef::Config[:knife][:batali_blacklist].include?(c_name)
            ckbks[c_name] = []
            meta['versions'].each do |info|
              ckbks[c_name] << info['version']
            end
          end
        end
      end

      def run_task(task)
        ui.stdout.print "#{ui.color('[Batali]', :green, :bold)}: #{task}... "
        begin
          value = yield if block_given?
          ui.info ui.color('complete', :green)
          value
        rescue => e
          ui.info ui.color('failed', :red, :bold)
          puts e.backtrace.join("\n")
          raise e
        end
      end

    end
  end
end
