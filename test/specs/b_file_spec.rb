require 'batali'
require 'tmpdir'
require 'minitest/autorun'

describe Batali::Struct do
  before do
    @cache = Dir.mktmpdir('batali-test')
  end

  after do
    FileUtils.rm_rf(@cache)
  end

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
        ['fubar', Smash.new(:path => '/the/path')],
      ]
    end
  end
end

# NOTE: The b_files directory has a collection of batali files. We
# simply load them, and ensure expected state
describe Batali::BFile do
  let(:base_path) { File.expand_path(File.join(File.dirname(__FILE__), 'b_files')) }

  describe 'Batali.1' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.1'), @cache)
    end
    let(:bfile) { @bfile }

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
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.2'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have a single source' do
      bfile.source.size.must_equal 1
      bfile.source.first.class.must_equal Batali::Origin::RemoteSite
      bfile.source.first.endpoint.must_equal 'http://example.com'
    end

    it 'should have multiple cookbooks' do
      bfile.cookbook.size.must_equal 5
    end

    it 'should have correct cookbook types' do
      bfile.cookbook.all? { |c| c.is_a?(Batali::BFile::Cookbook) }.must_equal true
    end

    it 'should have correct cookbook information' do
      [
        ['users'],
        ['example', '1.0'],
        ['fubar', '~> 3.0'],
        ['ohay', '> 2', '< 9'],
        ['finale'],
      ].each do |args|
        ckbk = bfile.cookbook.detect { |c| c.name == args.first }
        ckbk.wont_be :nil?
        ckbk.name.must_equal args.first
        constraint = args.slice(1, args.size)
        if constraint.empty?
          ckbk.constraint.must_be_nil
        else
          ckbk.constraint.must_equal constraint
        end
      end
    end
  end

  describe 'Batali.3' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.3'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have a single cookbook' do
      bfile.cookbook.size.must_equal 1
    end

    it 'should have two sources' do
      bfile.source.size.must_equal 2
    end

    it 'should have correct source information' do
      bfile.source.detect { |s| s.endpoint == 'http://example.com' }.wont_be :nil?
      bfile.source.detect { |s| s.endpoint == 'http://other.example.com' }.wont_be :nil?
    end

    it 'should have a custom name' do
      bfile.source.detect { |s|
        s.endpoint == 'http://other.example.com'
      }.name.must_equal 'custom'
    end
  end

  describe 'Batali.4' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.4'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have the proper restriction' do
      bfile.restrict.size.must_equal 1
      bfile.restrict.first.class.must_equal Batali::BFile::Restriction
      bfile.restrict.first.cookbook.must_equal 'users'
      bfile.restrict.first.source.must_equal 'custom'
    end
  end

  describe 'Batali.5' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.5'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have local metadata loaded cookbook' do
      bfile.cookbook.size.must_equal 1
      bfile.cookbook.first.name.must_equal 'test-cook'
      bfile.cookbook.first.path.wont_be :nil?
    end

    it 'should use relative path for metadata directory' do
      bfile.cookbook.size.must_equal 1
      Pathname.new(bfile.cookbook.first.path).must_be :relative?
    end
  end

  describe 'Batali.6' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.6'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have local metadata loaded cookbook when other cookbooks defined before' do
      bfile.cookbook.size.must_equal 2
      bfile.cookbook.map(&:name).sort.must_equal ['test-cook', 'users']
    end
  end

  describe 'Batali.7' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.7'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have local metadata loaded cookbook when other cookbooks defined after' do
      bfile.cookbook.size.must_equal 2
      bfile.cookbook.map(&:name).sort.must_equal ['test-cook', 'users']
    end
  end

  describe 'Batali.8' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.8'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have source and default chef server' do
      bfile.chef_server.size.must_equal 1
      bfile.source.size.must_equal 1
      bfile.chef_server.first.endpoint.must_equal 'https://localhost:443'
    end
  end

  describe 'Batali.9' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.9'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have source and custom chef server' do
      bfile.chef_server.size.must_equal 1
      bfile.source.size.must_equal 1
      bfile.chef_server.first.endpoint.must_equal 'https://example.com'
    end
  end

  describe 'Batali.10' do
    before do
      @bfile = Batali::BFile.new(File.join(base_path, 'Batali.10'), @cache)
    end
    let(:bfile) { @bfile }

    it 'should have source and two chef servers' do
      bfile.chef_server.size.must_equal 2
      bfile.source.size.must_equal 1
      bfile.chef_server.first.endpoint.must_equal 'https://example.com'
      bfile.chef_server.last.endpoint.must_equal 'https://srv.example.com'
    end
  end
end
