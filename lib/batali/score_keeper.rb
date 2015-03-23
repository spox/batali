require 'batali'

module Batali
  # Provide scores for units
  class ScoreKeeper < Grimoire::UnitScoreKeeper

    attribute :manifest, Manifest, :required => true

    # Always prefer higher scoring units
    #
    # @return [Symbol] :highscore
    def preferred_score
      :highscore
    end

    # Provide score for given unit
    #
    # @param unit [Unit] unit to score
    # @param idx [Integer] current index location
    # @return [Numeric, NilClass]
    def score_for(unit, idx)
      multiplier = 1
      manifest_unit = manifest.cookbook.detect do |m_unit|
        m_unit.name == unit.name
      end
      if(manifest_unit)
        if(manifest_unit.version == unit.version)
          multiplier = 10000000
        else
          if(UnitRequirement.new("~> #{manifest_unit.version}").satisfied_by?(unit.version))
            multiplier = 1000000
          elsif(UnitRequirement.new("~> #{manifest_unit.version.segments.slice(0,2).join('.')}").satisfied_by?(unit.version))
            distance = (manifest_unit.version.segments[1] - unit.version.segments[1])
            if(distance > 0)
              distance = 1.0 / distance
            else
              distance = 0
            end
            multiplier = 1000 + (1000 * distance)
          else
            distance = (manifest_unit.version.segments.first - unit.version.segments.first)
            if(distance > 0)
              distance = 1.0 / distance
            else
              distance = 0
            end
            multiplier = 100 + (100 * distance)
          end
        end
      end
      score = []
      unit.version.segments.reverse.each_with_index.map do |val, pos|
        if(val == 0)
          score.push 0
        else
          score.push (2 - (1.0 / val)) * ((pos + 1)**10)
        end
      end
      score = score.inject(&:+) * multiplier
      debug "Score <#{unit.name}:#{unit.version}>: #{score}"
      score
    end

  end
end
