require 'batali'

module Batali
  class Command

    # Resolve cookbooks
    class Resolve < Command

      def execute!
        file = BFile.new(File.join(Dir.pwd, 'Batali'))
        system = Grimoire::System.new
        run_action 'Loading sources' do
          file.source.map(&:units).flatten.map do |unit|
            system.add_unit(unit)
          end
          nil
        end
        requirements = Grimoire::RequirementList.new(
          :name => :batali_resolv,
          :requirements => file.cookbook.map{ |ckbk|
            [ckbk.name, *(ckbk.constraint ? ckbk.constraint : '> 0')]
          }
        )
        solv = Grimoire::Solver.new(
          :requirements => requirements,
          :system => system
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
          ui.info "Found #{results.size} solutions for defined requirements."
          ui.info 'Ideal solution:'
          ui.puts ideal_solution.units.sort_by(&:name).map{|u| "#{u.name}<#{u.version}>"}
        end
      end

    end

  end
end
