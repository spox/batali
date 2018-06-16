require "batali"
require "tempfile"
require "rubygems/package"
require "zlib"

module Batali
  class Command
    # Generate a supermarket
    class Supermarket < Batali::Command

      # Generate supermarket
      def execute!
        ui.info "Batali supermarket generator #{ui.color("started", :bold)}"
        if config[:skip_install]
          ui.warn "Skipping cookbook installation."
        else
          Install.new(config.merge(:ui => ui, :install => {}), arguments).execute!
        end
        run_action "Prepare supermarket destination directory" do
          FileUtils.mkdir_p(File.join(config[:supermarket_path], "api", "v1", "cookbooks"))
          FileUtils.mkdir_p(config[:assets_path])
          nil
        end
        new_universe = new_universe_file = universe_diff = nil
        run_action "Generate supermarket universe.json file" do
          new_universe, new_universe_file = generate_universe
          nil
        end
        unless config[:universe_only]
          if config[:clean_assets]
            Dir.glob(File.join(config[:assets_path], "*")).each do |old_asset|
              FileUtils.rm(old_asset)
            end
          end
          new_assets = generate_cookbook_assets
          valid_items = new_universe.values.map(&:values).flatten.map do |info|
            File.basename(info[:download_url])
          end
          prune_universe(valid_items)
          populate_universe(valid_items)
        end
        run_action "Write supermarket universe file" do
          FileUtils.cp(
            new_universe_file.path,
            File.join(config[:supermarket_path], "universe")
          )
          FileUtils.chmod(0644, File.join(config[:supermarket_path], "universe"))
          new_universe_file.delete
          nil
        end
        ui.info "Batali supermarket generator #{ui.color("complete!", :bold, :green)}"
        ui.puts "  Supermarket content written to: #{config[:supermarket_path]}"
      end

      # Generate compressed cookbook assets
      def generate_cookbook_assets
        manifest.cookbook.map do |ckbk|
          base_name = "#{ckbk.name}-#{ckbk.version}.tgz"
          ckbk_name = infrastructure? ? "#{ckbk.name}-#{ckbk.version}" : ckbk.name
          tar_ckbk_name = "#{ckbk.name}-#{ckbk.version}"
          ckbk_content_path = File.join("cookbooks", ckbk_name)
          ckbk_path = File.join(config[:assets_path], base_name)
          unless File.exist?(ckbk_path)
            ckbk_io = File.open(ckbk_path, "wb")
            gz_io = Zlib::GzipWriter.new(ckbk_io, Zlib::BEST_COMPRESSION)
            begin
              gz_io.mtime = Time.now
              Gem::Package::TarWriter.new(gz_io) do |tar|
                unless File.directory?(ckbk_content_path)
                  raise "Cookbook path not found! Run `install`. (#{ckbk_content_path})"
                end
                Dir.glob(File.join(ckbk_content_path, "**", "**", "*")).each do |c_file|
                  next unless File.file?(c_file)
                  stat = File.stat(c_file)
                  c_path = c_file.sub(File.join(ckbk_content_path, ""), "")
                  tar.add_file_simple(File.join(tar_ckbk_name, c_path), stat.mode, stat.size) do |dst|
                    File.open(c_file, "rb") do |src|
                      until src.eof?
                        dst.write src.read(4096)
                      end
                    end
                  end
                end
              end
            ensure
              gz_io.close
            end
            base_name
          end
        end.compact
      end

      # Prune assets from universe
      #
      # @param items [Array<String>] names of assets
      # TODO: This is a stub for custom action
      def prune_universe(items)
      end

      # Add assets to universe
      #
      # @param items [Array<String>] names of assets
      # TODO: This is a stub for custom action
      def populate_universe(items)
      end

      # Generate the supermarket universe.json file
      #
      # @return [Smash, File] universe content hash, universe file
      def generate_universe
        universe = Smash.new.tap do |uni|
          manifest.cookbook.each do |ckbk|
            uni.set(ckbk.name, ckbk.version.to_s,
                    Smash.new(
              :location_type => config[:location_type],
              :location_path => File.join(config[:remote_supermarket_url], "api", "v1"),
              :download_url => File.join(
                config[:remote_supermarket_url],
                config[:download_prefix],
                "#{ckbk.name}-#{ckbk.version}.tgz"
              ),
              :dependencies => Smash[
                ckbk.dependencies.map do |dep|
                  [dep.name, dep.requirement]
                end
              ],
            ))
          end
        end

        new_universe_file = Tempfile.new("batali-universe")
        new_universe_file.puts MultiJson.dump(universe, :pretty => !!config[:pretty_universe])
        new_universe_file.flush
        new_universe_file.rewind
        [universe, new_universe_file]
      end
    end
  end
end
