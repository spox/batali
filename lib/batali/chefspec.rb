require 'batali'
require 'stringio'
require 'fileutils'
require 'tmpdir'

module ChefSpec
  class Batali

    class << self
      extend Forwardable
      def_delegators :instance, :setup!, :teardown!
    end

    include Singleton

    def initialize
      @vendor_path = Dir.mktmpdir
    end

    def setup!
      output = ''
      begin
        ::Batali::Command::Update.new(
          Smash.new(
            :file => File.join(Dir.pwd, 'Batali'),
            :path => @vendor_path,
            :update => {
              :install => true
            },
            :ui => Bogo::Ui.new(
              :app_name => 'Batali',
              :output_to => StringIO.new(output)
            )
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

    def teardown!
      if(File.directory?(@vendor_path))
        FileUtils.rm_rf(@vendor_path)
      end
    end

  end
end

RSpec.configure do |config|
  config.before(:suite){ ChefSpec::Batali.setup! }
  config.after(:suite){ ChefSpec::Batali.teardown! }
end
