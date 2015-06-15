require 'batali'

module Batali

  class UnitLoader < Utility

    include Bogo::Memoization

    attribute :file, BFile, :required => true
    attribute :system, Grimoire::System, :required => true
    attribute :cache, String, :required => true

    # Populate the system with units
    #
    # @return [self]
    def populate!
      memoize(:populate) do
        (file.source + file.chef_server).each do |src|
          src.units.find_all do |unit|
            if(restrictions[unit.name])
              restrictions[unit.name] == src.identifier
            else
              true
            end
          end.each do |unit|
            system.add_unit(unit)
          end
        end
        file.cookbook.each do |ckbk|
          if(ckbk.path)
            source = Origin::Path.new(
              :name => ckbk.name,
              :path => ckbk.path
            )
          elsif(ckbk.git)
            source = Origin::Git.new(
              :name => ckbk.name,
              :url => ckbk.git,
              :ref => ckbk.ref || 'master',
              :cache => cache
            )
          end
          if(source)
            system.add_unit(source.units.first)
          end
        end
      end
    end

    # @return [Smash]
    def restrictions
      memoize(:restrictions) do
        rest = (file.restrict || Smash.new).to_smash
        file.cookbook.each do |ckbk|
          if(ckbk.path)
            rest[ckbk.name] = Smash.new(:path => ckbk.path).checksum
          elsif(ckbk.git)
            rest[ckbk.name] = Smash.new(
              :url => ckbk.git,
              :ref => ckbk.ref
            ).checksum
          end
        end
        rest
      end
    end

  end

end
