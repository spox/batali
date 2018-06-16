require "stringio"
require "batali"
require "tmpdir"
require "minitest/autorun"

describe Batali::Command do
  before do
    @cache = Dir.mktmpdir("batali-test")
    @command = Batali::Command.new(
      Smash.new(
        :file => File.join(
          File.dirname(__FILE__),
          "b_files/set1/Batali"
        ),
        :cache_directory => @cache,
        :dry_run => true,
        :ui => Bogo::Ui.new(:output_to => StringIO.new("")),
      ),
      []
    )
  end

  after do
    FileUtils.rm_rf(@cache)
  end

  let(:command) { @command }

  it "should load a Batali file with given path" do
    command.batali_file.class.must_equal Batali::BFile
    command.batali_file.cookbook.first.name.must_equal "users"
  end

  it "should load a batali.manifest in the same directory as the Batali file" do
    command.manifest.path.must_equal File.join(File.dirname(command.options[:file]), "batali.manifest")
    command.manifest.cookbook.first.name.must_equal "users"
    command.manifest.cookbook.first.version.must_equal Batali::UnitVersion.new("1.7.0")
  end

  it "should provide custom cache directory" do
    command.options[:cache_directory].must_equal @cache
  end

  it "should provide not execute dry run block when dry run is enabled" do
    result = false
    command.dry_run("action") do
      result = true
    end
    result.must_equal false
  end

  it "should execute dry run block when dry run is not enabled" do
    result = false
    command.options[:dry_run] = false
    command.dry_run("action") do
      result = true
    end
    result.must_equal true
  end
end
