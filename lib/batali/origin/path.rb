require 'batali'

module Batali
  class Origin
    # Fetch unit from local path
    class Path < Origin

      class Metadata < AttributeStruct

        def depends(*args)
          set!(:version, args)
          self
        end

      end

      include Bogo::Memoization

      attribute :path, String, :required => true

      def initialize(*_)
        super
        self.identifier = Smash.new(:path => path).checksum
        unless(name?)
          self.name = self.identifier
        end
      end

      # @return [Array<Unit>]
      def units
        memoize(:units) do
          info = load_metadata
          [
            Unit.new(
              :name => info[:name],
              :version => info[:version],
              :dependencies => info[:depends],
              :source => Smash.new(
                :type => :path,
                :version => info[:version],
                :dependencies => info[:depends]
              )
            )
          ]
        end
      end

      # @return [Smash] metadata information
      def load_metadata
        memoize(:metadata) do
          if(File.exists?(json = File.join(path, 'metadata.json')))
            MultiJson.load(json).to_smash
          elsif(File.exists?(rb = File.join(path, 'metadata.rb')))
            struct = Metadata.new
            struct.set_state!(:value_collapse => true)
            File.readlines(rb).find_all do |line|
              line.start_with?('name') ||
                line.start_with?('version') ||
                line.start_with?('depends')
            end.each do |line|
              struct.instance_eval(line)
            end
            struct._dump.to_smash
          else
            raise Errno::ENOENT.new('No metadata file available to load!')
          end
        end
      end

    end
  end
end
