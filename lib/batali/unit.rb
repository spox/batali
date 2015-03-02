require 'batali'

module Batali
  # Customized Unit
  class Unit < Grimoire::Unit
    attribute :source, Source, :required => true, :coerce => lambda{|v| Batali::Source.build(v)}
  end
end
