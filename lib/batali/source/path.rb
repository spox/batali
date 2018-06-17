require "batali"
require "fileutils"
require "tmpdir"

module Batali
  # Source of asset
  class Source
    # Path based source
    class Path < Source

      # @return [Array<String>] default ignore globs
      DEFAULT_IGNORE = [".git*"]
      # @return [Array<String>] valid ignore file names
      IGNORE_FILE = ["chefignore", ".chefignore"]

      include Bogo::Memoization

      attribute :path, String, :required => true, :equivalent => true

      def initialize(*_, &block)
        super
        self.path = Utility.clean_path(path)
      end

      # @return [String] directory containing contents
      def asset
        memoize(:asset) do
          dir = Dir.mktmpdir
          chefignore = IGNORE_FILE.map do |c_name|
            c_path = Utility.join_path(path, c_name)
            c_path if File.exist?(c_path)
          end.compact.first
          chefignore = chefignore ? File.readlines(chefignore) : []
          chefignore += DEFAULT_IGNORE
          chefignore.uniq!
          files_to_copy = Dir.glob(File.join(path, "{.[^.]*,**}", "**", "{*,*.*,.*}"))
          files_to_copy = files_to_copy.map do |file_path|
            next unless File.file?(file_path)
            relative_path = file_path.sub("#{path}#{File::SEPARATOR}", "")
            relative_path unless chefignore.detect { |ig| File.fnmatch(ig, relative_path) }
          end.compact
          files_to_copy.each do |relative_path|
            new_path = Utility.join_path(dir, relative_path)
            FileUtils.mkdir_p(File.dirname(new_path))
            FileUtils.cp(Utility.join_path(path, relative_path), new_path)
          end
          dir
        end
      end
    end
  end
end
