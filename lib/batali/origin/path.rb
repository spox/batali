require "batali"

module Batali
  class Origin
    # Fetch unit from local path
    class Path < Origin

      # Helper class for loading metadata ruby files
      class Metadata < AttributeStruct

        # Perform constant lookup if required
        #
        # @return [Constant]
        def self.const_missing(const)
          [::Object, ::ObjectSpace].map do |root|
            if root.const_defined?(const)
              root.const_get(const)
            end
          end.compact.first || super
        end

        def depends(*args)
          set!(:depends, args)
          self
        end
      end

      include Bogo::Memoization

      attribute :path, String, :required => true

      def initialize(*_)
        super
        self.path = Utility.clean_path(path)
        self.identifier = Smash.new(:path => path).checksum
        unless name?
          self.name = identifier
        end
      end

      # @return [Array<Unit>]
      def units
        memoize(:units) do
          info = load_metadata
          if info[:depends]
            unless info[:depends].first.is_a?(Array)
              info[:depends] = [info[:depends]]
            end
            info[:depends] = info[:depends].map do |dep|
              case dep
              when String
                [dep, "> 0"]
              else
                dep.size == 1 ? dep.push("> 0") : dep
              end
            end
          end
          [
            Unit.new(
              :name => info[:name],
              :version => info[:version],
              :dependencies => info.fetch(:depends, []),
              :source => Smash.new(
                :type => :path,
                :version => info[:version],
                :path => path,
                :dependencies => info.fetch(:depends, []),
                :cache_path => cache_path,
              ),
            ),
          ]
        end
      end

      # @return [Smash] metadata information
      def load_metadata
        memoize(:metadata) do
          if File.exist?(json = File.join(path, "metadata.json"))
            MultiJson.load(File.read(json)).to_smash
          elsif File.exist?(rb = File.join(path, "metadata.rb"))
            struct = Metadata.new
            struct.set_state!(:value_collapse => true)
            struct.instance_eval(File.read(rb), rb, 1)
            struct._dump.to_smash
          else
            raise Errno::ENOENT.new("Failed to locate metadata file in cookbook directory! (path: #{path})")
          end
        end
      end
    end
  end
end
