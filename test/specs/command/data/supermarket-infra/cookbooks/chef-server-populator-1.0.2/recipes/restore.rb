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
  command 'chef-server-ctl stop erchef'
  creates '/etc/opscode/restore.json'
end

execute 'backup chef server bookshelf stop' do
  command 'chef-server-ctl stop bookshelf'
  creates '/etc/opscode/restore.json'
end

#Drop and Restore entire chef database from file
execute 'dropping chef database' do
  command '/opt/opscode/embedded/bin/dropdb opscode_chef'
  user 'opscode-pgsql'
  creates '/etc/opscode/restore.json'
end

execute 'restoring chef data' do
  command "/opt/opscode/embedded/bin/pg_restore --create --dbname=postgres #{file}"
  user 'opscode-pgsql'
  creates '/etc/opscode/restore.json'
end

%w( opscode-pgsql opscode_chef opscode_chef_ro ).each do |pg_role|
  execute "set #{pg_role} db permissions" do
    command "/opt/opscode/embedded/bin/psql -d opscode_chef -c 'GRANT TEMPORARY, CREATE, CONNECT ON DATABASE opscode_chef TO \"#{pg_role}\"'"
    user 'opscode-pgsql'
    creates '/etc/opscode/restore.json'
  end
end

execute 'remove existing bookshelf data' do
  command "rm -rf /var/opt/opscode/bookshelf/data/"
  creates '/etc/opscode/restore.json'
end

execute 'restore bookshelf data' do
  command "tar xzf #{data} -C /var/opt/opscode/bookshelf/"
  creates '/etc/opscode/restore.json'
end

execute 'update local superuser cert' do
  command lazy{
    pivotal_cert = File.read('/etc/opscode/pivotal.cert')
    "/opt/opscode/embedded/bin/psql -d opscode_chef -c \"update users set public_key=E'#{pivotal_cert}' where username='pivotal'\""
  }
  user 'opscode-pgsql'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server bookshelf start' do
  command 'chef-server-ctl start bookshelf'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server start' do
  command 'chef-server-ctl start erchef'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server wait for erchef' do
  command 'sleep 10'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server reindex' do
  command 'chef-server-ctl reindex'
  creates '/etc/opscode/restore.json'
end

execute 'restore chef server restart' do
  command 'chef-server-ctl restart'
  creates '/etc/opscode/restore.json'
end

directory '/etc/opscode'

file '/etc/opscode/restore.json' do
  content JSONCompat.to_json_pretty(
    :date => Time.now.to_i,
     :file => file
  )
end
