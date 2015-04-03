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
    def score_for(unit, *args)
      opts = args.detect{|a| a.is_a?(Hash)} || {}
      multiplier = 1
      manifest_unit = manifest.cookbook.detect do |m_unit|
        m_unit.name == unit.name
      end
      if(manifest_unit)
        # If the unit version matches the manifest version, this
        # should be _the_ preferred version
        if(manifest_unit.version == unit.version)
          multiplier = 10000000
        elsif(opts[:solver].new_world)
          new_world_unit = opts[:solver].new_world.units.detect do |n_unit|
            n_unit.name == unit.name &&
              n_unit.version == unit.version
          end
          multiplier = 10000000 if new_world_unit
        else
          # If the unit version satisfies within the patch segment of
          # the manifest version score those versions highest for upgrade
          if(UnitRequirement.new("~> #{manifest_unit.version}").satisfied_by?(unit.version))
            multiplier = 1000000
          else
            # If the unit version satisfies within the minor or major
            # version segments of the manifest version, bump score
            # value up (with satisfaction within minor segment being
            # worth more than satisfaction within major segment)
            pos = UnitRequirement.new("~> #{manifest_unit.version.segments.slice(0,2).join('.')}").satisfied_by?(unit.version) ? 1 : 0
            multi_val = pos == 1 ? 1000 : 100
            distance = (manifest_unit.version.segments[pos] - unit.version.segments[pos])
            if(distance > 0)
              distance = 1.0 / distance
            else
              distance = 0
            end
            multiplier = multi_val + (multi_val * distance)
          end
        end
      end
      score = []
      # Generate a "value" for each segment of the version with
      # growing importance (major > minor > patch)
      unit.version.segments.reverse.each_with_index.map do |val, pos|
        if(val == 0)
          score.push 0
        else
          score.push (2 - (1.0 / val)) * ((pos + 1)**10)
        end
      end
      # Sum the score for each segment to provide the score for the
      # version and multiply by defined multiplier to force higher
      # score when manifest drives desire for versions closer to
      # version defined within manifest
      score = score.inject(&:+) * multiplier
      debug "Score <#{unit.name}:#{unit.version}>: #{score}"
      score
    end

  end
end
