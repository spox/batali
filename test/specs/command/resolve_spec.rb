require_relative "command_helper"

REMOTE_SITE_CACHE_ID = "7402ae8bc051165aced4c70ce76dcced8e79d22436f11d43e322111ab2445737"

describe Batali::Command::Resolve do
  before do
    @cache = Dir.mktmpdir("batali-cache")
    FileUtils.mkdir_p(
      File.join(
        @cache, "remote_site",
        REMOTE_SITE_CACHE_ID
      )
    )
    FileUtils.cp(
      File.join(File.dirname(__FILE__), "data", "universe.json"),
      File.join(
        @cache, "remote_site",
        REMOTE_SITE_CACHE_ID,
        "universe.json"
      )
    )
    @cwd = Dir.mktmpdir("batali-cwd")
  end

  after do
    FileUtils.rm_rf(@cache)
    FileUtils.rm_rf(@cwd)
  end

  describe "Single path resolution" do
    describe "Single cookbook" do
      before do
        File.open(File.join(@cwd, "Batali"), "w") do |file|
          file.puts <<-EOF
Batali.define do
  source 'https://supermarket.chef.io'
  cookbook 'users'
end
EOF
        end
        quiet_in_directory(@cwd) do
          Batali::Command::Resolve.new(
            Smash.new(:cache_directory => @cache),
            Array.new
          ).execute!
        end
      end

      it "should create manifest file with single entry" do
        File.exist?(File.join(@cwd, "batali.manifest")).must_equal true
        contents = MultiJson.load(File.read(File.join(@cwd, "batali.manifest"))).to_smash
        contents["cookbook"].size.must_equal 1
        contents["cookbook"].first["version"].must_equal "2.0.0"
      end
    end

    describe "Multiple cookbooks" do
      before do
        File.open(File.join(@cwd, "Batali"), "w") do |file|
          file.puts <<-EOF
Batali.define do
  source 'https://supermarket.chef.io'
  cookbook 'users'
  cookbook 'chef-server-populator'
end
EOF
        end
        quiet_in_directory(@cwd) do
          Batali::Command::Resolve.new(
            Smash.new(:cache_directory => @cache),
            Array.new
          ).execute!
        end
      end

      it "should create manifest file with all entries and dependencies" do
        File.exist?(File.join(@cwd, "batali.manifest")).must_equal true
        contents = MultiJson.load(File.read(File.join(@cwd, "batali.manifest"))).to_smash
        expected = Smash.new(
          "users" => "2.0.0",
          "chef-server-populator" => "1.2.2",
          "chef-server" => "4.1.0",
          "chef-ingredient" => "0.16.0",
          "apt-chef" => "0.2.2",
          "apt" => "2.9.2",
          "yum-chef" => "0.2.2",
          "yum" => "3.8.2",
        )
        contents["cookbook"].size.must_equal expected.size
        expected.each do |name, version|
          result = contents["cookbook"].detect do |cook|
            cook["name"] == name &&
              cook["version"] == version
          end || {}
          result["name"].must_equal name
          result["version"].must_equal version
        end
      end
    end
  end

  describe "Multiple path resolution (infrastructure-mode)" do
    describe "Single cookbook" do
      before do
        File.open(File.join(@cwd, "Batali"), "w") do |file|
          file.puts <<-EOF
Batali.define do
  source 'https://supermarket.chef.io'
  cookbook 'users', '> 1.0'
end
EOF
        end
        quiet_in_directory(@cwd) do
          Batali::Command::Resolve.new(
            Smash.new(
              :cache_directory => @cache,
              :infrastructure => true,
            ),
            Array.new
          ).execute!
        end
      end

      it "should create manifest file with multiple entries" do
        File.exist?(File.join(@cwd, "batali.manifest")).must_equal true
        contents = MultiJson.load(File.read(File.join(@cwd, "batali.manifest"))).to_smash
        contents["cookbook"].size.must_equal 14
        contents["cookbook"].all? do |item|
          Gem::Version.new(item["version"]) > Gem::Version.new("1.0.0")
        end.must_equal true
      end
    end
  end
end
