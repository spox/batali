require "git"
require "batali"

# Batali namespace
module Batali
  # Helper module for git interactions
  module Git

    # @return [String] path to repository clone
    def base_path
      Utility.join_path(cache_path, Base64.urlsafe_encode64(url))
    end

    # Clone the repository to the local machine
    #
    # @return [TrueClass]
    def clone_repository
      if File.directory?(base_path)
        repo = ::Git.open(base_path)
        repo.checkout("master")
        repo.pull
        repo.fetch
      else
        ::Git.clone(url, base_path)
      end
      true
    end

    # Duplicate reference and store
    #
    # @return [String] commit SHA
    # @note this will update ref to SHA
    def ref_dup
      git = ::Git.open(base_path)
      git.checkout(ref)
      git.pull("origin", ref)
      self.ref = git.log.first.sha
      self.path = Utility.join_path(cache_path, "git", ref)
      unless File.directory?(path)
        FileUtils.mkdir_p(path)
        FileUtils.cp_r(Utility.join_path(base_path, "."), path)
        FileUtils.rm_rf(Utility.join_path(path, ".git"))
      end
      path
    end

    # Load attributes into class
    def self.included(klass)
      klass.class_eval do
        attribute :url, String, :required => true, :equivalent => true
        attribute :ref, String, :required => true, :equivalent => true

        @@locks = {}
        @@lock_init = Mutex.new

        def self.path_lock(path)
          @@lock_init.synchronize do
            if !@@locks[path]
              @@locks[path] = Mutex.new
            end
          end
          if block_given?
            @@locks[path].synchronize do
              yield
            end
          else
            @@locks[path]
          end
        end
      end
    end
  end
end
