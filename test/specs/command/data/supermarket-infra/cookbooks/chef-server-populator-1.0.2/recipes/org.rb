conf_dir = node[:chef_server_populator][:base_path]
node.set['chef-server'][:configuration][:default_orgname] = node[:chef_server_populator][:default_org]

org = node[:chef_server_populator][:solo_org]
user = node[:chef_server_populator][:solo_org_user]
pass = user[:pass] || SecureRandom.base64

execute 'create populator user' do
  command "chef-server-ctl user-create #{user[:name]} #{user[:first]} #{user[:last]} #{user[:email]} #{pass}"
  not_if "chef-server-ctl user-show #{user[:name]}"
end

execute 'set populator user key' do
  command "chef-server-ctl add-user-key #{user[:name]} #{conf_dir}/#{user[:pub_key]} --key-name populator"
  not_if "chef-server-ctl list-user-keys #{user[:name]} | grep '^key_name: populator$'"
end

execute 'delete default user key' do
  command "chef-server-ctl delete-user-key #{user[:name]} default"
  only_if "chef-server-ctl list-user-keys #{user[:name]} | grep '^key_name: default$'"
end

execute 'create populator org' do
  command "chef-server-ctl org-create #{org[:org_name]} #{org[:full_name]} -a #{user[:name]}"
  not_if "chef-server-ctl org-list | grep '^#{org[:org_name]}$'"
  if org[:org_name] == node[:chef_server_populator][:default_org]
    notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
  end
end

execute 'add populator org validator key' do
  command "chef-server-ctl add-client-key #{org[:org_name]} #{org[:org_name]}-validator #{conf_dir}/#{org[:validator_pub_key]} --key-name populator"
  not_if "chef-server-ctl list-client-keys #{org[:org_name]} #{org[:org_name]}-validator | grep '^key_name: populator$'"
end

execute 'remove populator org default validator key' do
  command "chef-server-ctl delete-client-key #{org[:org_name]} #{org[:org_name]}-validator default"
  only_if "chef-server-ctl list-client-keys #{org[:org_name]} #{org[:org_name]}-validator | grep '^key_name: default$'"
end
