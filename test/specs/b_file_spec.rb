require 'batali'
require 'minitest/autorun'

describe Batali::Struct do

  describe 'Cookbook entries' do
    it 'should accept single cookbook' do
      struct = Batali::Struct.new do
        cookbook 'users'
      end
      struct._dump['cookbook'].must_equal [['users']]
    end

    it 'should accept multiple cookbooks' do
      struct = Batali::Struct.new do
        cookbook 'users'
        cookbook 'example'
      end
      struct._dump['cookbook'].must_equal [['users'], ['example']]
    end

    it 'should accept single cookbook with single constraint' do
      struct = Batali::Struct.new do
        cookbook 'users', '1.0'
      end
      struct._dump['cookbook'].must_equal [['users', '1.0']]
    end

    it 'should accept multiple cookbooks with single constraint' do
      struct = Batali::Struct.new do
        cookbook 'users', '1.0'
        cookbook 'example'
      end
      struct._dump['cookbook'].must_equal [['users', '1.0'], ['example']]
    end

    it 'should accept multiple cookbooks with constraints' do
      struct = Batali::Struct.new do
        cookbook 'users', '1.0'
        cookbook 'example', '2.0'
      end
      struct._dump['cookbook'].must_equal [['users', '1.0'], ['example', '2.0']]
    end

    it 'should accept single cookbook with multiple constraints' do
      struct = Batali::Struct.new do
        cookbook 'users', '> 1.0', '< 2.0'
      end
      struct._dump['cookbook'].must_equal [['users', '> 1.0', '< 2.0']]
    end

    it 'should accept multiple cookbooks with multiple constraints' do
      struct = Batali::Struct.new do
        cookbook 'users', '> 1.0', '< 2.0'
        cookbook 'example', '> 2.0', '< 3.0'
      end
      struct._dump['cookbook'].must_equal [['users', '> 1.0', '< 2.0'], ['example', '> 2.0', '< 3.0']]
    end

    it 'should accept single cookbook with hash arguments' do
      struct = Batali::Struct.new do
        cookbook 'users', :path => '/some/path'
      end
      struct._dump['cookbook'].must_equal [['users', Smash.new(:path => '/some/path')]]
    end

    it 'should accept multiple cookbooks with mixed arguments' do
      struct = Batali::Struct.new do
        cookbook 'users'
        cookbook 'example', '1.0'
        cookbook 'fubar', :path => '/the/path'
      end
      struct._dump['cookbook'].to_smash.must_equal [
        ['users'],
        ['example', '1.0'],
        ['fubar', Smash.new(:path => '/the/path')]
      ]
    end

  end

end

describe Batali::BFile do



end
