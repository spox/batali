require "batali"

module Batali
  # Cookbook source origin
  class Origin < Utility
    autoload :ChefServer, "batali/origin/chef_server"
    autoload :RemoteSite, "batali/origin/remote_site"
    autoload :Git, "batali/origin/git"
    autoload :Path, "batali/origin/path"

    attribute :name, String, :required => true
    attribute :cache_path, String, :required => true
    attribute :identifier, String

    def initialize(*_, &block)
      super
      self.cache_path = Utility.clean_path(cache_path)
    end

    # @return [Array<Unit>] all units
    def units
      raise NotImplementedError.new "Abstract class"
    end
  end
end
