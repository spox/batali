include_recipe 'chef-server-populator::configurator'

knife_cmd = "#{node[:chef_server_populator][:knife_exec]}"
knife_opts = '-c /etc/opscode/pivotal.rb'

ssl_port = %w(chef-server configuration nginx ssl_port).inject(node) do |memo, key|
  memo[key] || break
end
ssl_port = ":#{ssl_port}" if ssl_port

pg_cmd = "/opt/chef-server/embedded/bin/psql -d opscode_chef"

if(node[:chef_server_populator][:databag])
  begin
    data_bag(node[:chef_server_populator][:databag]).each do |item_id|
      item = data_bag_item(node[:chef_server_populator][:databag], item_id)
      next unless item['chef_server']
      client = item['id']
      pub_key = item['chef_server']['client_key']
      enabled = item['chef_server']['enabled']
      types = [item['chef_server'].fetch('type', 'client')].flatten
      admin = item['chef_server'].fetch('admin', true)
      password = item['chef_server'].fetch('password', SecureRandom.urlsafe_base64(23))
      full_name = item.fetch('full_name', client.capitalize)
      first_name = full_name.split(' ').first
      last_name = full_name.split(' ').last
      email = item.fetch('email', "#{client}@example.com")
      orgs = item['chef_server'].fetch('orgs', {})
      org, options = orgs.first
      if(org)
        knife_url = "-s https://127.0.0.1/organizations/#{org}"
      else
        knife_url = "-s https://127.0.0.1"
      end
      if(options)
        if(options.has_key?('enabled'))
          enabled = options[:enabled]
        end
        if(options.has_key?('admin'))
          admin = options[:admin]
        end
      end
      if(item['enabled'] == false)
        if(types.include?('client'))
          execute "delete client: #{client}" do
            command "#{knife_cmd} client delete #{client} -d #{knife_opts} #{knife_url}"
            only_if "#{knife_cmd} client list #{knife_opts} #{knife_url} | tr -d ' ' | grep '^#{client}$'"
            retries 10
          end
        end
        if(types.include?('user'))
          execute "remove user: #{client} from #{org}" do
            command "chef-server-ctl org-user-remove #{org} #{client}"
          end
          execute "delete user: #{client}" do
            command "chef-server-ctl user-delete #{client}"
            only_if "chef-server-list user-list | tr -d ' ' | grep '^#{client}$'"
          end
        end
      else

        if(pub_key)
          key_file = "#{Chef::Config[:file_cache_path]}/#{client}.pub"
          file key_file do
            backup false
            content pub_key
            mode '0400'
          end
        end

        if(types.include?('org'))
          execute 'create org' do
            command "chef-server-ctl org-create #{client} #{full_name}"
            not_if "chef-server-ctl org-list | grep '^#{client}$'"
            if client == node[:chef_server_populator][:default_org]
              notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
            end
          end
          execute 'add org validator key' do
            command "chef-server-ctl add-client-key #{client} #{client}-validator #{key_file} --key-name populator"
            only_if pub_key
            not_if "chef-server-ctl list-client-keys #{client} #{client}-validator | grep '^key_name: populator$'"
          end
          execute 'remove org default validator key' do
            command "chef-server-ctl delete-client-key #{client} #{client}-validator default"
            only_if "chef-server-ctl list-client-keys #{client} #{client}-validator | grep '^key_name: default$'"
          end
        end

        if(types.include?('client'))
          execute "create client: #{client}" do
            command "#{knife_cmd} client create #{client}#{' --admin' if admin} -d #{knife_url} #{knife_opts}"
            not_if "#{knife_cmd} client list #{knife_url} #{knife_opts} | tr -d ' ' | grep '^#{client}$'"
            retries 10
          end
          if(pub_key)
            execute "set client key: #{client}" do
              command "chef-server-ctl add-client-key #{org || node[:chef_server_populator][:default_org]} #{client} #{key_file} --key-name populator"
              not_if "chef-server-ctl list-client-keys #{org || node[:chef_server_populator][:default_org]} #{client} | grep '^key_name: populator$'"
            end
            execute "delete default client key: #{client}" do
              command "chef-server-ctl delete-client-key #{org || node[:chef_server_populator][:default_org]} #{client} default"
              only_if "chef-server-ctl list-client-keys #{org || node[:chef_server_populator][:default_org]} #{client} | grep '^key_name: default$'"
            end
          end
        end

        if(types.include?('user'))
          execute "create user: #{client}" do
            command "chef-server-ctl user-create #{client} #{first_name} #{last_name} #{email} #{password} > /dev/null 2>&1"
            not_if "chef-server-ctl user-list | grep '^#{client}$'"
          end
          if(pub_key)
            execute "set user key: #{client}" do
              command "chef-server-ctl add-user-key #{client} #{key_file} --key-name populator"
              not_if "chef-server-ctl list-user-keys #{client} | grep '^key_name: populator$'"
            end
            execute "delete default user key: #{client}" do
              command "chef-server-ctl delete-user-key #{client} default"
              only_if "chef-server-ctl list-user-keys #{client} | grep '^key_name: default$'"
            end
          end
          execute "set user org: #{client}" do
            command "chef-server-ctl org-user-add #{org} #{client} #{'--admin' if admin}"
            only_if { org }
          end
        end
      end
    end
  rescue Net::HTTPServerException
    Chef::Log.warn 'Chef server populator failed to locate population data bag'
  end
end
