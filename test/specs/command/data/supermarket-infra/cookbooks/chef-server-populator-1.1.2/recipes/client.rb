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
    items = data_bag(node[:chef_server_populator][:databag]).map do |bag_item|
      item = data_bag_item(node[:chef_server_populator][:databag], bag_item).fetch('chef_server', {})
      if item.empty?
        Chef::Log.info("No chef-server data for #{bag_item['id']}")
      end
      item.merge('client' => data_bag_item(node[:chef_server_populator][:databag], bag_item)['id'],
                 'pub_key' => item['client_key'],
                 'enabled' => item['enabled'],
                 'admin' => item.fetch('admin', true),
                 'password' => item.fetch('password', SecureRandom.urlsafe_base64(23)),
                 'orgs' => item.fetch('orgs', {}))
    end
    orgs = items.select { |item| item.fetch('type', []).include?('org') }
    users = items.select { |item| item.fetch('type', []).include?('user') }
    clients = items.select { |item| item.fetch('type', []).include?('client') }

    # Org Setup
    orgs.each do |item|
      if(item['enabled']==true)
        item['full_name'] = item.fetch('full_name', item['client'].capitalize)
        execute "create org: #{item['client']}" do
          item.merge('full_name' => item.fetch('full_name', item['client'].capitalize))
          command "chef-server-ctl org-create #{item['client']} #{item['full_name']}"
          not_if "chef-server-ctl org-list | grep '^#{item['client']}$'"
          if item['client'] == node[:chef_server_populator][:default_org]
            notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
          end
        end
        if(item['pub_key'])
          key_file = "#{Chef::Config[:file_cache_path]}/#{item['client']}.pub"
          file key_file do
            backup false
            content item['pub_key']
            mode '0400'
          end
        end
        execute "add org validator key: #{item['client']}" do
          command "chef-server-ctl add-client-key #{item['client']} #{item['client']}-validator #{key_file} --key-name populator"
          not_if "chef-server-ctl list-client-keys #{item['client']} #{item['client']}-validator | grep 'name: populator$'"
        end
        execute "remove org default validator key: #{item['client']}" do
          command "chef-server-ctl delete-client-key #{item['client']} #{item['client']}-validator default"
          only_if "chef-server-ctl list-client-keys #{item['client']} #{item['client']}-validator | grep 'name: default$'"
        end
      else
        Chef::Log.info("#{item['client']} is not enabled, skipping.")
      end
    end
    # User Setup
    users.each do |item|
      org, options = item['orgs'].first
      item['org'] = org
      if(options)
        if(options.has_key?('enabled'))
          item[:enabled] = options[:enabled]
        end
        if(options.has_key?('admin'))
          item[:admin] = options[:admin]
        end
      end
      if(item['enabled'] == false)
        execute "remove user: #{item['client']} from #{item['org']}" do
          command "chef-server-ctl org-user-remove #{item['org']} #{item['client']}"
        end
        execute "delete user: #{item['client']}" do
          command "chef-server-ctl user-delete #{item['client']}"
          only_if "chef-server-list user-list | tr -d ' ' | grep '^#{item['client']}$'"
        end
      else
        if(item['pub_key'])
          key_file = "#{Chef::Config[:file_cache_path]}/#{item['client']}.pub"
          file key_file do
            backup false
            content item['pub_key']
            mode '0400'
          end
        end
        item['full_name'] = item.fetch('full_name', item['client'].capitalize)
        first_name = item['full_name'].split(' ').first.capitalize
        last_name = item['full_name'].split(' ').last.capitalize
        email = item.fetch('email', "#{item['client']}@example.com")
        execute "create user: #{item['client']}" do
          command "chef-server-ctl user-create #{item['client']} #{first_name} #{last_name} #{email} #{item['password']} > /dev/null 2>&1"
          not_if "chef-server-ctl user-list | grep '^#{item['client']}$'"
        end
        if(item['pub_key'])
          execute "set user key: #{item['client']}" do
            command "chef-server-ctl add-user-key #{item['client']} #{key_file} --key-name populator"
            not_if "chef-server-ctl list-user-keys #{item['client']} | grep 'name: populator$'"
          end
          execute "delete default user key: #{item['client']}" do
            command "chef-server-ctl delete-user-key #{item['client']} default"
            only_if "chef-server-ctl list-user-keys #{item['client']} | grep 'name: default$'"
          end
        end
        execute "set user org: #{item['client']}" do
          command "chef-server-ctl org-user-add #{item['org']} #{item['client']} #{'--admin' if item['admin']}"
        end
      end
    end
    # Client Setup
    clients.each do |item|
      org, options = item['orgs'].first
      if(org)
        knife_url = "-s https://127.0.0.1/organizations/#{org}"
      else
        knife_url = "-s https://127.0.0.1"
      end
      if(options)
        if(options.has_key?('enabled'))
          item[:enabled] = options[:enabled]
        end
        if(options.has_key?('admin'))
          item[:admin] = options[:admin]
        end
      end
      if(item['enabled'] == false)
        execute "delete client: #{item['client']}" do
          command "#{knife_cmd} client delete #{item['client']} -d #{knife_opts} #{knife_url}"
          only_if "#{knife_cmd} client list #{knife_opts} #{knife_url} | tr -d ' ' | grep '^#{item['client']}$'"
          retries 10
        end
      else
        if(item['pub_key'])
          key_file = "#{Chef::Config[:file_cache_path]}/#{item['client']}.pub"
          file key_file do
            backup false
            content item['pub_key']
            mode '0400'
          end
        end
        execute "create client: #{item['client']}" do
          command "#{knife_cmd} client create #{item['client']}#{' --admin' if item['admin']} -d #{knife_url} #{knife_opts}"
          not_if "#{knife_cmd} client list #{knife_url} #{knife_opts} | tr -d ' ' | grep '^#{item['client']}$'"
          retries 10
        end
        if(item['pub_key'])
          execute "set client key: #{item['client']}" do
            command "chef-server-ctl add-client-key #{org || node[:chef_server_populator][:default_org]} #{item['client']} #{key_file} --key-name populator"
            not_if "chef-server-ctl list-client-keys #{org || node[:chef_server_populator][:default_org]} #{item['client']} | grep 'name: populator$'"
          end
          execute "delete default client key: #{item['client']}" do
            command "chef-server-ctl delete-client-key #{org || node[:chef_server_populator][:default_org]} #{item['client']} default"
            only_if "chef-server-ctl list-client-keys #{org || node[:chef_server_populator][:default_org]} #{item['client']} | grep 'name: default$'"
          end
        end
      end
    end
  rescue Net::HTTPServerException
    Chef::Log.warn 'Chef server populator failed to locate population data bag'
  end
end
