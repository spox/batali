#!/usr/bin/env ruby

require 'fog'
require 'multi_json'
require 'mixlib/shellout'

DEFAULT_CONFIGURATION_PATH = '/etc/opscode/populator/backup.json'

if(ARGV.size > 1 || (ARGV.first && !File.exists?(ARGV.first.to_s)))
  puts 'Usage: chef-server-backup CONFIG_FILE_PATH'
  exit
else
  config = MultiJson.load(
    File.read(
      ARGV.first || DEFAULT_CONFIGURATION_PATH
    ),
    :symbolize_keys => true
  )
end

server_manifest = MultiJson.load(
  File.read('/opt/opscode/version-manifest.json'),
  :symbolize_keys => true
)

prefix = [
  Time.now.to_i,
  "ver_#{server_manifest[:version]}",
  config[:filename]
].join('-')

db_file = File.join(
  config[:dir],
  "#{prefix}.dump"
)

data_file = File.join(
  config[:dir],
  "#{prefix}.tgz"
)

# stop server
stop_service = Mixlib::ShellOut.new('chef-server-ctl stop')
stop_service.run_command
stop_service.error!

begin
  backup = Mixlib::ShellOut.new([
      '/opt/opscode/embedded/bin/pg_dump',
      "opscode_chef --username=opscode-pgsql --format=custom -f #{db_file}"
    ].join(' '),
    :user => 'opscode-pgsql'
  )

  backup.run_command
  backup.error!

  backup_data = Mixlib::ShellOut.new(
    "tar -czf #{data_file} -C /var/opt/opscode/bookshelf data"
  )
  backup_data.run_command
  backup_data.error!
ensure
  start_service = Mixlib::ShellOut.new('chef-server-ctl start')
  start_service.run_command
  start_service.error!
end

remote_creds = [:remote, :connection].inject(config) do |memo, key|
  memo[key] || break
end
remote_directory = [:remote, :directory].inject(config) do |memo, key|
  memo[key] || break
end

if(remote_creds)
  if(remote_directory)
    remote = Fog::Storage.new(remote_creds)
    directory = remote.directories.create(:key => remote_directory)
    [db_file, data_file].each do |file|
      name = File.basename(file)
      directory.files.create(:key => name, :body => open(file))
      directory.files.create(:key => "latest#{File.extname(file)}", :body => open(file))
    end
  else
    $stderr.puts 'ERROR: No remote directory defined for backup storage!'
    exit -1
  end
else
  puts 'WARN: No remote credentials found. Backup is local only!'
end
