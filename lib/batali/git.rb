require 'git'
require 'batali'

module Batali
  module Git

    # @return [String] path to repository clone
    def base_path
      File.join(cache, Base64.urlsafe_encode64(url))
    end

    # Clone the repository to the local machine
    #
    # @return [TrueClass]
    def clone_repository
      if(File.directory?(base_path))
        repo = ::Git.open(base_path)
        repo.checkout('master')
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
      git.pull('origin', ref)
      self.ref = git.log.first.sha
      self.path = File.join(cache, ref)
      unless(File.directory?(path))
        FileUtils.mkdir_p(path)
        FileUtils.cp_r(File.join(base_path, '.'), path)
        FileUtils.rm_rf(File.join(path, '.git'))
      end
      self.path
    end

    # Load attributes into class
    def self.included(klass)
      klass.class_eval do
        attribute :url, String, :required => true
        attribute :ref, String, :required => true
        attribute :cache, String
      end
    end

  end
end
