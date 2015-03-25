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

# NOTE: The b_files directory has a collection of batali files. We
# simply load them, and ensure expected state
describe Batali::BFile do

  let(:base_path){ File.expand_path(File.join(File.dirname(__FILE__), 'b_files')) }

  describe 'Batali.1' do

    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.1'))
    end
    let(:bfile){ @bfile }

    it 'should have a single source' do
      bfile.source.size.must_equal 1
      bfile.source.first.class.must_equal Batali::Origin::RemoteSite
      bfile.source.first.endpoint.must_equal 'http://example.com'
    end

    it 'should have a single cookbook' do
      bfile.cookbook.size.must_equal 1
      bfile.cookbook.first.class.must_equal Batali::BFile::Cookbook
      bfile.cookbook.first.name.must_equal 'users'
    end

  end

  describe 'Batali.2' do

    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.2'))
    end
    let(:bfile){ @bfile }

    it 'should have a single source' do
      bfile.source.size.must_equal 1
      bfile.source.first.class.must_equal Batali::Origin::RemoteSite
      bfile.source.first.endpoint.must_equal 'http://example.com'
    end

    it 'should have multiple cookbooks' do
      bfile.cookbook.size.must_equal 5
    end

    it 'should have correct cookbook types' do
      bfile.cookbook.all?{|c| c.is_a?(Batali::BFile::Cookbook) }.must_equal true
    end

    it 'should have correct cookbook information' do
      [
        ['users'],
        ['example', '1.0'],
        ['fubar', '~> 3.0'],
        ['ohay', '> 2', '< 9'],
        ['finale']
      ].each do |args|
        ckbk = bfile.cookbook.detect{|c| c.name == args.first}
        ckbk.wont_be :nil?
        ckbk.name.must_equal args.first
        constraint = args.slice(1, args.size)
        ckbk.constraint.must_equal constraint.empty? ? nil : constraint
      end
    end

  end

  describe 'Batali.3' do

    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.3'))
    end
    let(:bfile){ @bfile }

    it 'should have a single cookbook' do
      bfile.cookbook.size.must_equal 1
    end

    it 'should have two sources' do
      bfile.source.size.must_equal 2
    end

    it 'should have correct source information' do
      bfile.source.detect{|s| s.endpoint == 'http://example.com'}.wont_be :nil?
      bfile.source.detect{|s| s.endpoint == 'http://other.example.com'}.wont_be :nil?
    end

    it 'should have a custom name' do
      bfile.source.detect{|s|
        s.endpoint == 'http://other.example.com'
      }.name.must_equal 'custom'
    end

  end

  describe 'Batali.4' do

    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.4'))
    end
    let(:bfile){ @bfile }

    it 'should have the proper restriction' do
      bfile.restrict.size.must_equal 1
      bfile.restrict.first.class.must_equal Batali::BFile::Restriction
      bfile.restrict.first.cookbook.must_equal 'users'
      bfile.restrict.first.source.must_equal 'custom'
    end

  end

  describe 'Batali.5' do

    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.5'))
    end
    let(:bfile){ @bfile }

    it 'should have local metadata loaded cookbook' do
      bfile.cookbook.size.must_equal 1
      bfile.cookbook.first.name.must_equal 'test-cook'
      bfile.cookbook.first.path.wont_be :nil?
    end

  end

  describe 'Batali.6' do

    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.6'))
    end
    let(:bfile){ @bfile }

    it 'should have local metadata loaded cookbook when other cookbooks defined before' do
      bfile.cookbook.size.must_equal 2
      bfile.cookbook.map(&:name).sort.must_equal ['test-cook', 'users']
    end

  end

  describe 'Batali.7' do

    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.7'))
    end
    let(:bfile){ @bfile }

    it 'should have local metadata loaded cookbook when other cookbooks defined after' do
      bfile.cookbook.size.must_equal 2
      bfile.cookbook.map(&:name).sort.must_equal ['test-cook', 'users']
    end

  end

end
