require 'batali'

module Batali
  # Provide scores for units
  class ScoreKeeper < Grimoire::UnitScoreKeeper

    attribute :manifest, Manifest, :required => true

    # Provide score for given unit
    #
    # @param unit [Unit]
    # @return [Numeric, NilClass]
    def score_for(unit)
      manifest.include?(unit) ? 0 : nil
    end

  end
end
