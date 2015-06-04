require 'batali'
require 'fileutils'
require 'tmpdir'

module Batali
  # Source of asset
  class Source
    # Path based source
    class Path < Source

      # @return [Array<String>] default ignore globs
      DEFAULT_IGNORE = ['.git*']
      # @return [Array<String>] valid ignore file names
      IGNORE_FILE = ['chefignore', '.chefignore']

      include Bogo::Memoization

      attribute :path, String, :required => true, :equivalent => true

      # @return [String] directory containing contents
      def asset
        memoize(:asset) do
          dir = Dir.mktmpdir
          chefignore = IGNORE_FILE.map do |c_name|
            c_path = File.join(path, c_name)
            c_path if File.exists?(c_path)
          end.compact.first
          chefignore = chefignore ? File.readlines(chefignore) : []
          chefignore += DEFAULT_IGNORE
          chefignore.uniq!
          files_to_copy = Dir.glob(File.join(path, '{.[^.]*,**}', '**', '{*,*.*,.*}'))
          files_to_copy = files_to_copy.map do |file_path|
            next unless File.file?(file_path)
            relative_path = file_path.sub("#{path}/", '')
            relative_path unless chefignore.detect{|ig| File.fnmatch(ig, relative_path)}
          end.compact
          files_to_copy.each do |relative_path|
            new_path = File.join(dir, relative_path)
            FileUtils.mkdir_p(File.dirname(new_path))
            FileUtils.cp(File.join(path, relative_path), new_path)
          end
          dir
        end
      end

    end
  end
end
