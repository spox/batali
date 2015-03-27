require 'batali'

module Batali
  # Provide scores for units
  class ScoreKeeper < Grimoire::UnitScoreKeeper

    attribute :manifest, Manifest, :required => true

    SCORE_MULTIPLIER_MAX  = 10_000_000
    SCORE_MULTIPLIER_MID  =  1_000_000
    SCORE_MULTIPLIER_BASE =        100
    SCORE_MULTIPLIER_MIN  =          1

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

      multiplier = score_multiplier(unit, manifest_unit)
      score_arr = version_segment_score(unit, multiplier)
      # Sum the score for each segment to provide the score for the
      # version and multiply by defined multiplier to force higher
      # score when manifest drives desire for versions closer to
      # version defined within manifest
      score = score_arr.inject(&:+) * multiplier
      debug "Score <#{unit.name}:#{unit.version}>: #{score}"
      score
    end

    private

    # Create a score based on the version segments (major, minor, patch)
    #   Manifest will create a higher score for versions closest to specification
    #
    # @param unit [Unit] unit to score
    # @param multiplier [Numeric] weight based on version constraint
    # @return [Numeric]
    def score_multiplier(unit, manifest_unit)
      if(manifest_unit.nil?)
        SCORE_MULTIPLIER_MIN
      elsif(manifest_unit.version == unit.version)
        # If the unit version matches the manifest version, this
        # should be _the_ preferred version
        SCORE_MULTIPLIER_MAX
      elsif(UnitRequirement.new("~> #{manifest_unit.version}").satisfied_by?(unit.version))
        SCORE_MULTIPLIER_MID
      else
        # If the unit version satisfies within the minor or major
        # version segments of the manifest version, bump score
        # value up (with satisfaction within minor segment being
        # worth more than satisfaction within major segment)
        unit_req = UnitRequirement.new("~> #{manifest_unit.version.segments.slice(0,2).join('.')}")
        pos = unit_req.satisfied_by?(unit.version) ? 1 : 0
        requirement_multiplier = pos.zero? ? SCORE_MULTIPLIER_BASE : (SCORE_MULTIPLIER_BASE * 10)
        version_distance = manifest_unit.version.segments[pos] - unit.version.segments[pos]
        version_dist_multiplier = (version_distance > 0) ? (1.0 / distance) : 0
        requirement_multiplier + (requirement_multiplier * version_dist_multiplier)
      end
    end

    # Create a score for each version segment (major, minor, patch)
    #   Manifest will create a higher score for versions closest to specification
    #
    # @param unit [Unit] unit to score
    # @param multiplier [Numeric] weight based on version constraint
    # @return [Numeric]
    def version_segment_score(unit, multiplier)
      score = []
      # Generate a "value" for each segment of the version with
      # growing importance (major > minor > patch)
      # TODO: add comment about this math
      unit.version.segments.reverse.each_with_index.map do |val, pos|
        res = (val == 0) ? 0 : (2 - (1.0 / val)) * ((pos + 1)**10)
        score.push(res)
      end
      score
    end

  end
end
