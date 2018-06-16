require "webrick"
require_relative "command_helper"

describe Batali::Command::Supermarket do
  describe "Infrastructure supermarket generation" do
    before do
      @cwd = Dir.mktmpdir("batali-supermarket-cwd")
      FileUtils.mkdir(File.join(@cwd, "cookbooks"))
      FileUtils.cp_r(
        File.join(
          File.dirname(__FILE__),
          "data",
          "supermarket-infra",
          "."
        ),
        @cwd
      )
      quiet_in_directory(@cwd) do
        Batali::Command::Supermarket.new(
          Smash.new(
            :skip_install => true,
            :supermarket_path => "supermarket",
            :assets_path => "supermarket/assets",
            :location_type => "batali-test",
            :remote_supermarket_url => "http://localhost:8989",
            :download_prefix => "/assets",
          ),
          Array.new
        ).execute!
      end
      @manifest = MultiJson.load(
        File.read(
          File.join(
            @cwd, "batali.manifest"
          )
        )
      )
      @universe = MultiJson.load(
        File.read(
          File.join(
            @cwd, "supermarket", "universe"
          )
        )
      )
    end

    after do
      FileUtils.rm_rf(@cwd)
    end

    it "should create a supermarket directory" do
      File.directory?(File.join(@cwd, "supermarket")).must_equal true
    end

    it "should create a supermarket universe file" do
      File.file?(File.join(@cwd, "supermarket", "universe")).must_equal true
    end

    it "should create asset files" do
      @manifest["cookbook"].each do |ckbk|
        File.exist?(
          File.join(
            @cwd, "supermarket", "assets", "#{ckbk["name"]}-#{ckbk["version"]}.tgz"
          )
        ).must_equal true
      end
    end

    it "should contain all manifest items in universe" do
      @manifest["cookbook"].each do |ckbk|
        @universe.keys.must_include ckbk["name"]
        @universe[ckbk["name"]].keys.must_include ckbk["version"]
      end
    end

    describe "Generated supermarket usage" do
      before do
        @srv_thread = Thread.new do
          @webrick = WEBrick::HTTPServer.new(
            :Port => 8989,
            :DocumentRoot => File.join(@cwd, "supermarket"),
          )
          @webrick.start
        end
        sleep(0.1) && (sleep(0.1) until @webrick.status == :Running)
        @usage_dir = Dir.mktmpdir("batali-supermarket-usage")
        @cache_dir = File.join(@usage_dir, ".cache")
        FileUtils.mkdir(@cache_dir)
        File.open(File.join(@usage_dir, "Batali"), "w") do |f|
          f.puts(
            MultiJson.dump(
              :source => [["http://localhost:8989"]],
              :cookbook => [
                :name => "postgresql",
              ],
            )
          )
        end
        quiet_in_directory(@usage_dir) do
          Batali::Command::Update.new(
            Smash.new(
              :cache_directory => @cache_dir,
              :update => {
                :install => true,
              },
            ),
            Array.new
          ).execute!
        end
      end

      after do
        FileUtils.rm_rf(@usage_dir)
        @webrick.shutdown
        @srv_thread.join
        sleep(0.1) while @webrick.status == :Running
        @webrick = nil
      end

      it "should create a new manifest document" do
        File.file?(File.join(@usage_dir, "batali.manifest")).must_equal true
      end

      it "should have installed the postgresql cookbook" do
        File.directory?(File.join(@usage_dir, "cookbooks", "postgresql")).must_equal true
        File.file?(File.join(@usage_dir, "cookbooks", "postgresql", "metadata.rb")).must_equal true
      end
    end
  end
end
