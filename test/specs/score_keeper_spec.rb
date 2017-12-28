require 'batali'
require 'minitest/autorun'

describe Batali::ScoreKeeper do
  it 'should require a manifest file' do
    -> { Batali::ScoreKeeper.new }.must_raise ArgumentError
    -> { Batali::ScoreKeeper.new(:manifest => Batali::Manifest.new); true }.call.must_equal true
  end

  describe 'Scoring' do
    before do
      @score_keeper = Batali::ScoreKeeper.new(
        :manifest => Batali::Manifest.new(
          :cookbook => [
            :name => 'example',
            :version => '1.0.1',
            :source => Batali::Source.new,
          ],
        ),
      )
    end
    let(:score_keeper) { @score_keeper }

    it 'should prefer a high score' do
      score_keeper.preferred_score.must_equal :highscore
    end

    it 'should provide a `#score_for` method' do
      score_keeper.respond_to?(:score_for).must_equal true
    end

    it 'should accept two arguments for `#score_for` method' do
      score_keeper.method(:score_for).arity.abs.must_equal 2
    end

    it 'should score to provide ordering for highest version at least distance' do
      expected_order = [
        '1.0.1',
        '1.0.13',
        '1.0.10',
        '1.1.2',
        '0.9.8',
        '0.8.2',
        '0.8.0',
      ]
      scored = expected_order.map do |version|
        [
          version,
          score_keeper.score_for(
            Batali::Unit.new(
              :name => 'example',
              :version => version,
              :source => Batali::Source.new,
            )
          ),
        ]
      end.sort_by(&:last).reverse
      scored.map(&:first).must_equal expected_order
    end
  end
end
