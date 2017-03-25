require "batali"
require "stringio"
require "fileutils"
require "tmpdir"

# ChefSpec namespace
module ChefSpec
  # Batali integration class
  class Batali
    class << self
      extend Forwardable
      def_delegators :instance, :setup!, :teardown!
    end

    include Singleton

    # Create new instance
    def initialize
      @vendor_path = Utility.clean_path(Dir.mktmpdir)
    end

    # Setup the environment (load cookbooks)
    def setup!
      output = ""
      begin
        ::Batali::Command::Update.new(
          Smash.new(
            :file => Utility.join_path(Dir.pwd, "Batali"),
            :path => @vendor_path,
            :update => {
              :install => true,
            },
            :ui => Bogo::Ui.new(
              :app_name => "Batali",
              :output_to => StringIO.new(output),
            ),
          ),
          []
        ).execute!
        RSpec.configure do |config|
          config.cookbook_path = @vendor_path
        end
      rescue => e
        $stderr.puts "Batali failure - #{e.class}: #{e.message}"
        $stderr.puts output
        raise
      end
    end

    # Clean up after complete
    def teardown!
      if File.directory?(@vendor_path)
        FileUtils.rm_rf(@vendor_path)
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) { ChefSpec::Batali.setup! }
  config.after(:suite) { ChefSpec::Batali.teardown! }
end
