if(node[:chef_server_populator][:default_org].nil?)
  node.default[:chef_server_populator][:default_org] = node[:chef_server_populator][:server_org]
end

include_recipe 'chef-server-populator::configurator'

# if backup pull files include restore

if(node[:chef_server_populator][:backup][:remote][:connection])
  chef_gem 'miasma'
  require 'miasma'
  remote_creds = node[:chef_server_populator][:backup][:remote][:connection]
  remote_directory = node[:chef_server_populator][:backup][:remote][:directory]
  remote = Miasma.api(:provider => remote_creds[:provider].to_s.downcase, :type => 'storage', :credentials => remote_creds[:credentials])
  remote_bucket = remote.buckets.get(remote_directory)
  if(remote_bucket && gz_file = remote_bucket.files.get(File.join(node[:chef_server_populator][:backup][:remote][:file_prefix], 'latest.tgz')))
    dump_file = remote_bucket.files.get(File.join(node[:chef_server_populator][:backup][:remote][:file_prefix], 'latest.dump'))
    local_gz = '/tmp/latest.tgz'
    local_dump = '/tmp/latest.dump'
    File.open(local_gz, 'wb') do |file|
      while(data = gz_file.body.readpartial(2048))
        file.print data
      end
    end
    File.open(local_dump, 'wb') do |file|
      while(data = dump_file.body.readpartial(2048))
        file.print data
      end
    end
    node.set[:chef_server_populator][:restore][:file] = local_dump
    node.set[:chef_server_populator][:restore][:data] = local_gz
  end
end

if(local_gz && local_dump)

  include_recipe 'chef-server-populator::restore'

else

  include_recipe 'chef-server-populator::org'

  knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"
  knife_opts = "-s https://127.0.0.1/organizations/#{node[:chef_server_populator][:server_org]} -c /etc/opscode/pivotal.rb"

  node[:chef_server_populator][:clients].each do |client, pub_key|
    execute "create client: #{client}" do
      command "#{knife_cmd} client create #{client} --admin -d #{knife_opts} > /dev/null 2>&1"
      not_if "#{knife_cmd} client list #{knife_opts}| tr -d ' ' | grep '^#{client}$'"
      retries 5
    end
    if(pub_key && node[:chef_server_populator][:base_path])
      pub_key_path = File.join(node[:chef_server_populator][:base_path], pub_key)
      execute "remove default public key for #{client}" do
        command "chef-server-ctl delete-client-key #{node[:chef_server_populator][:server_org]} #{client} default"
        only_if "chef-server-ctl list-client-keys #{node[:chef_server_populator][:server_org]} #{client} | grep 'name: default$'"
      end
      execute "set public key for: #{client}" do
      if node['chef-server'][:version].to_f >= 12.1
        command "chef-server-ctl add-client-key #{node[:chef_server_populator][:server_org]} #{client} --public-key-path #{pub_key_path} --key-name populator"
      else
        command "chef-server-ctl add-client-key #{node[:chef_server_populator][:server_org]} #{client} #{pub_key_path} --key-name populator"
      end
        not_if "chef-server-ctl list-client-keys #{node[:chef_server_populator][:server_org]} #{client} | grep 'name: populator$'"
      end
    end
  end

  execute 'install chef-server-populator cookbook' do
    command "#{knife_cmd} cookbook upload chef-server-populator #{knife_opts} -o #{Chef::Config[:cookbook_path].join(':')} --include-dependencies"
    only_if do
      node[:chef_server_populator][:cookbook_auto_install]
    end
    retries 5
  end

end
