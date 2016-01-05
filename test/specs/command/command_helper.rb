require 'batali'
require 'tmpdir'
require 'stringio'
require 'minitest/autorun'

def quiet_in_directory(dir)
  o_out = $stdout
  output = StringIO.new('')
  $stdout = output
  Dir.chdir(dir) do
    yield
  end
  $stdout = o_out
  output.rewind
  output
end
