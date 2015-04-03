require 'batali'

module Batali
  class Command

    # Resolve cookbooks
    class Resolve < Command

      # Resolve dependencies and constraints. Output results to stdout
      # and dump serialized manifest
      def execute!
        system = Grimoire::System.new
        run_action 'Loading sources' do
          UnitLoader.new(
            :file => batali_file,
            :system => system,
            :cache => cache_directory(:git)
          ).populate!
          nil
        end
        requirements = Grimoire::RequirementList.new(
          :name => :batali_resolv,
          :requirements => batali_file.cookbook.map{ |ckbk|
            [ckbk.name, (ckbk.constraint.nil? || ckbk.constraint.empty? ? ['> 0'] : ckbk.constraint)]
          }
        )
        solv = Grimoire::Solver.new(
          :requirements => requirements,
          :system => system,
          :score_keeper => score_keeper
        )
        if(opts[:infrastructure])
          infrastructure_resolution(solv)
        else
          single_path_resolution(solv)
        end
      end

      # @return [ScoreKeeper]
      def score_keeper
        memoize(:score_keeper) do
          sk_manifest = Manifest.new(:cookbook => manifest.cookbook)
          unless(opts[:least_impact])
            sk_manifest.cookbook.clear
          end
          sk_manifest.cookbook.delete_if do |unit|
            arguments.include?(unit.name)
          end
          ScoreKeeper.new(:manifest => sk_manifest)
        end
      end

      # Generate manifest comprised of units for single path resolution
      #
      # @param solv [Grimoire::Solver]
      # @return [TrueClass]
      def single_path_resolution(solv)
        original_units = Smash[
          [manifest.cookbook].flatten.compact.map do |unit|
            [unit.name, unit.version]
          end
        ]
        ui.info 'Performing single path resolution.'
        if(manifest.infrastructure)
          ui.ask 'Current manifest is resolved for infrastucture. Convert to single path?'
        end
        results = []
        run_action 'Resolving dependency constraints' do
          results = solv.generate!
          nil
        end
        if(results.empty?)
          ui.error 'No solutions found defined requirements!'
        else
          ideal_solution = results.pop
          dry_run('manifest file write') do
            run_action 'Writing manifest' do
              manifest = Manifest.new(
                :cookbook => ideal_solution.units,
                :infrastructure => false
              )
              File.open('batali.manifest', 'w') do |file|
                file.write MultiJson.dump(manifest, :pretty => true)
              end
              nil
            end
          end
          # ui.info "Number of solutions collected for defined requirements: #{results.size + 1}"
          ui.info 'Ideal solution:'
          solution = Smash[ideal_solution.units.map{|unit| [unit.name, unit.version]}]
          (original_units.keys + solution.keys).compact.uniq.sort.each do |unit_name|
            if(original_units[unit_name])
              if(solution[unit_name])
                if(solution[unit_name] == original_units[unit_name])
                  ui.puts "#{unit_name} <#{solution[unit_name]}>"
                else
                  ui.puts ui.color("#{unit_name} <#{original_units[unit_name]} -> #{solution[unit_name]}>", :yellow)
                end
              else
                ui.puts ui.color("#{unit_name} <#{original_units[unit_name]}>", :red)
              end
            else
              ui.puts ui.color("#{unit_name} <#{solution[unit_name]}>", :green)
            end
          end
        end
      end

      # Generate manifest comprised of units for entire infrastructure
      #
      # @param solv [Grimoire::Solver]
      # @return [TrueClass]
      def infrastructure_resolution(solv)
        ui.info 'Performing infrastructure path resolution.'
        if(manifest.infrastructure == false)
          ui.ask 'Current manifest is resolved single path. Convert to infrastructure?'
        end
        run_action 'Writing infrastructure manifest file' do
          File.open(manifest.path, 'w') do |file|
            manifest = Manifest.new(
              :cookbook => solv.world.units.values.flatten,
              :infrastructure => true
            )
            file.write MultiJson.dump(manifest, :pretty => true)
            nil
          end
        end
        solv.prune_world!
        ui.info 'Infrastructure manifest solution:'
        solv.world.units.sort_by(&:first).each do |name, units|
          ui.puts "#{name} <#{units.map(&:version).sort.map(&:to_s).join(', ')}>"
        end
      end

    end

  end
end
