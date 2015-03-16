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
            [ckbk.name, *(ckbk.constraint.nil? || ckbk.constraint.empty? ? ['> 0'] : ckbk.constraint)]
          }
        )
        solv = Grimoire::Solver.new(
          :requirements => requirements,
          :system => system,
          :score_keeper => score_keeper
        )
        if(opts[:infrastructure])
          ui.info 'Performing infrastructure path resolution.'
          run_action 'Writing infrastructure manifest file' do
            File.open('batali.manifest', 'w') do |file|
              manifest = Manifest.new(:cookbook => solv.world.units.values.flatten)
              file.write MultiJson.dump(manifest, :pretty => true)
              nil
            end
          end
        else
          original_units = Smash[
            [manifest.cookbook].flatten.compact.map do |unit|
              [unit.name, unit.version]
            end
          ]
          ui.info 'Performing single path resolution.'
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
                manifest = Manifest.new(:cookbook => ideal_solution.units)
                File.open('batali.manifest', 'w') do |file|
                  file.write MultiJson.dump(manifest, :pretty => true)
                end
                nil
              end
            end
            # ui.info "Number of solutions collected for defined requirements: #{results.size + 1}"
            ui.info 'Ideal solution:'
            ideal_solution.units.sort_by(&:name).map do |unit|
              output_args = ["#{unit.name} <#{unit.version}>"]
              unless(original_units.empty?)
                if(original_units[unit.name])
                  unless(original_units[unit.name] == unit.version)
                    output_args.first.replace "#{unit.name} <#{original_units[unit.name]} -> #{unit.version}>"
                    output_args.push(:yellow)
                  end
                else
                  output_args.push(:green)
                end
              end
              ui.puts ui.color(*output_args)
            end
          end
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

    end

  end
end
