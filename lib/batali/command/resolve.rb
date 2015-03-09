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
            :system => system
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
          ui.info "Found #{results.size} solutions for defined requirements."
          ui.info 'Ideal solution:'
          ui.puts ideal_solution.units.sort_by(&:name).map{|u| "#{u.name}<#{u.version}>"}
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
