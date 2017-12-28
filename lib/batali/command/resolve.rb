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
            :cache => cache_directory(:git),
            :auto_path_restrict => !infrastructure?,
          ).populate!
          nil
        end
        requirements = Grimoire::RequirementList.new(
          :name => :batali_resolv,
          :requirements => batali_file.cookbook.map { |ckbk|
            [ckbk.name, (ckbk.constraint.nil? || ckbk.constraint.empty? ? ['> 0'] : ckbk.constraint)]
          },
        )
        solv = Grimoire::Solver.new(
          :requirements => requirements,
          :system => system,
          :score_keeper => score_keeper,
        )
        if infrastructure?
          infrastructure_resolution(solv)
        else
          single_path_resolution(solv)
        end
      end

      # @return [ScoreKeeper]
      def score_keeper
        memoize(:score_keeper) do
          sk_manifest = Manifest.new(:cookbook => manifest.cookbook)
          unless config[:least_impact]
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
        if manifest.infrastructure
          ui.confirm 'Current manifest is resolved for infrastucture. Convert to single path?'
        end
        results = []
        run_action 'Resolving dependency constraints' do
          results = solv.generate!
          nil
        end
        if results.empty?
          ui.error 'No solutions found defined requirements!'
        else
          ideal_solution = results.pop
          ui.debug 'Full solution raw contents:'
          ideal_solution.units.each do |unit|
            ui.debug [unit.name, unit.version].join(' -> ')
          end
          dry_run('manifest file write') do
            run_action 'Writing manifest' do
              manifest = Manifest.new(
                :cookbook => ideal_solution.units,
                :infrastructure => false,
              )
              File.open('batali.manifest', 'w') do |file|
                file.write MultiJson.dump(manifest, :pretty => true)
              end
              nil
            end
          end
          # ui.info "Number of solutions collected for defined requirements: #{results.size + 1}"
          ui.info 'Ideal solution:'
          solution_units = Smash[ideal_solution.units.map { |unit| [unit.name, unit] }]
          manifest_units = Smash[manifest.cookbook.map { |unit| [unit.name, unit] }]
          (solution_units.keys + manifest_units.keys).compact.uniq.sort.each do |unit_name|
            if manifest_units[unit_name]
              if solution_units[unit_name]
                if solution_units[unit_name].same?(manifest_units[unit_name])
                  ui.puts "#{unit_name} <#{solution_units[unit_name].version}>"
                else
                  u_diff = manifest_units[unit_name].diff(solution_units[unit_name])
                  version_output = u_diff[:version] ? u_diff[:version].join(' -> ') : solution_units[unit_name].version
                  u_diff.delete(:version)
                  unless u_diff.empty?
                    diff_output = "[#{u_diff.values.map { |v| v.join(' -> ') }.join(' | ')}]"
                  end
                  ui.puts ui.color("#{unit_name} <#{version_output}> #{diff_output}", :yellow)
                end
              else
                ui.puts ui.color("#{unit_name} <#{manifest_units[unit_name].version}>", :red)
              end
            else
              ui.puts ui.color("#{unit_name} <#{solution_units[unit_name].version}>", :green)
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
        if manifest.infrastructure == false
          ui.ask 'Current manifest is resolved single path. Convert to infrastructure?'
        end
        run_action 'Resolving dependency constraints' do
          solv.prune_world!
          nil
        end
        dry_run('manifest file write') do
          run_action 'Writing infrastructure manifest file' do
            File.open(manifest.path, 'w') do |file|
              manifest = Manifest.new(
                :cookbook => solv.world.units.values.flatten,
                :infrastructure => true,
              )
              file.write MultiJson.dump(manifest, :pretty => true)
              nil
            end
          end
        end
        ui.info 'Infrastructure manifest solution:'

        solution_units = solv.world.units
        manifest_units = Smash.new.tap do |mu|
          manifest.cookbook.each do |unit|
            mu[unit.name] ||= []
            mu[unit.name] << unit
          end
        end
        (solution_units.keys + manifest_units.keys).compact.uniq.sort.each do |unit_name|
          if manifest_units[unit_name]
            if solution_units[unit_name]
              removed = manifest_units[unit_name].find_all do |m_unit|
                solution_units[unit_name].none? do |s_unit|
                  m_unit.same?(s_unit)
                end
              end.map { |u| [u.version, :red] }
              added = solution_units[unit_name].find_all do |s_unit|
                manifest_units[unit_name].none? do |m_unit|
                  s_unit.same?(m_unit)
                end
              end.map { |u| [u.version, :green] }
              persisted = solution_units[unit_name].find_all do |s_unit|
                manifest_units[unit_name].any? do |m_unit|
                  s_unit.same?(m_unit)
                end
              end.map { |u| [u.version, nil] }
              unit_versions = (removed + added + persisted).sort_by(&:first).map do |uv|
                uv.last ? ui.color(uv.first.to_s, uv.last) : uv.first.to_s
              end
              unless added.empty? && removed.empty?
                ui.puts "#{ui.color(unit_name, :yellow)} #{ui.color('<', :yellow)}#{unit_versions.join(ui.color(', ', :yellow))}#{ui.color('>', :yellow)}" # rubocop:disable Metrics/LineLength
              else
                ui.puts "#{unit_name} <#{unit_versions.join(', ')}>"
              end
            else
              ui.puts ui.color("#{unit_name} <#{manifest_units[unit_name].map(&:version).sort.map(&:to_s).join(', ')}>", :red) # rubocop:disable Metrics/LineLength
            end
          else
            ui.puts ui.color("#{unit_name} <#{solution_units[unit_name].map(&:version).sort.map(&:to_s).join(', ')}>", :green) # rubocop:disable Metrics/LineLength
          end
        end
      end
    end
  end
end
