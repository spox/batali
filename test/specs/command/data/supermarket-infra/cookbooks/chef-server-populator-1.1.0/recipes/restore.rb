#Determine if we're using a remote file or a local file.
if(URI(node[:chef_server_populator][:restore][:file]).scheme)
  local_file = File.join(node[:chef_server_populator][:restore][:local_path], 'chef_database_restore.dump')
  remote_file local_file do
    source node[:chef_server_populator][:restore][:file]
  end
  file = local_file
else
  file = node[:chef_server_populator][:restore][:file]
end

if(URI(node[:chef_server_populator][:restore][:data]).scheme)
  local_data = File.join(node[:chef_server_populator][:restore][:local_path], 'chef_data_restore.tar.gz')
  remote_file local_data do
    source node[:chef_server_populator][:restore][:data]
  end
  data = local_data
else
  data = node[:chef_server_populator][:restore][:data]
end

execute 'backup chef server stop' do
  command 'chef-server-ctl stop'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server start postgres' do
  command 'chef-server-ctl start postgresql'
  creates '/etc/opscode/restore.json'
end

#Drop and Restore entire chef database from file
execute 'restoring chef data' do
  command "/opt/opscode/embedded/bin/psql -f #{file} postgres"
  user 'opscode-pgsql'
  creates '/etc/opscode/restore.json'
end

execute 'remove existing data' do
  command "rm -rf /var/opt/opscode /etc/opscode"
  creates '/etc/opscode/restore.json'
end

execute 'restore tarball data' do
  command "tar xzf #{data} -C /"
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server restart' do
  command 'chef-server-ctl restart'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server wait for opscode-erchef' do
  command 'sleep 30'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server reindex' do
  command "for org in $(chef-server-ctl org-list) ; do chef-server-ctl reindex $org ; done"
  creates '/etc/opscode/restore.json'
end

directory '/etc/opscode'

file '/etc/opscode/restore.json' do
  content JSONCompat.to_json_pretty(
    :date => Time.now.to_i,
     :file => file
  )
end
