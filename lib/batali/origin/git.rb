require 'git'
require 'batali'

module Batali
  class Origin
    # Fetch unit from local path
    class Git < Path

      attribute :url, String, :required => true
      attribute :ref, String, :required => true
      attribute :cache, String, :required => true

      def initialize(args={})
        unless(args[:path])
          args[:path] = '/dev/null'
        end
        super
        self.identifier = Smash.new(
          :url => url,
          :ref => ref
        ).checksum
        unless(name?)
          self.name = self.identifier
        end
      end

      # @return [Array<Unit>]
      def units
        memoize(:g_units) do
          items = super
          items.first.source = Source::Git.new(
            :url => url,
            :ref => ref,
            :path => path
          )
          items
        end
      end

      # @return [Smash] metadata information
      def load_metadata
        fetch_repo
        super
      end

      # @return [String] path to repository
      def fetch_repo
        memoize(:fetch_repo) do
          clone_repository
          ref_dup
        end
      end

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
        self.ref = git.log.first.sha
        self.path = File.join(cache, ref)
        unless(File.directory?(path))
          FileUtils.mkdir_p(path)
          FileUtils.cp_r(File.join(base_path, '.'), path)
          FileUtils.rm_rf(File.join(path, '.git'))
        end
        self.path
      end

    end
  end
end
