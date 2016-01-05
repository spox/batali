default[:chef_server_populator][:configuration_directory] = '/etc/chef-server/populator'
default[:chef_server_populator][:base_path] = '/tmp/chef-server-populator'
default[:chef_server_populator][:clients] = {}
default[:chef_server_populator][:knife_exec] = '/usr/bin/knife'
default[:chef_server_populator][:user] = 'admin'
default[:chef_server_populator][:pem] = '/etc/chef-server/admin.pem'
default[:chef_server_populator][:databag] = nil
default[:chef_server_populator][:user_databag] = nil

default[:chef_server_populator][:endpoint] = nil

default[:chef_server_populator][:backup_gems][:miasma] = '~> 0.2'

# Deprecated in favor of endpoint
default[:chef_server_populator][:servername_override] = nil

# The :chef_server attribute is passed to chef-server cookbook
# Default the ttl since it kills runs with 403s on templates with
# annoying frequency
default[:chef_server_populator][:chef_server][:configuration][:opscode_erchef][:s3_url_ttl] = 3600

default[:chef_server_populator][:cookbook_auto_install] = true

default[:chef_server_populator][:restore][:file] = ''
default[:chef_server_populator][:restore][:data] = ''
default[:chef_server_populator][:restore][:local_path] = '/tmp/'

default[:chef_server_populator][:backup][:dir] = '/tmp/chef-server/backup'
default[:chef_server_populator][:backup][:filename] = 'chef-server-full'
default[:chef_server_populator][:backup][:remote][:connection] = {}
default[:chef_server_populator][:backup][:remote][:directory] = nil
default[:chef_server_populator][:backup][:schedule] = {
  :minute => '33',
  :hour => '3'
}

#The following attributes are provided as examples. In almost every
#imaginable case you will want to replace some or all of these with
#your own values.

default[:chef_server_populator][:solo_org] = {
  :org_name => 'inception_llc',
  :full_name => 'Chef Inception Organization',
  :validator_pub_key => 'validator_pub.pem'
}

default[:chef_server_populator][:solo_org_user] = {
  :name => 'populator',
  :first => 'Populator',
  :last => 'User',
  :email => 'pop@example.com',
  :pub_key => 'user_pub.pem'
}

default[:chef_server_populator][:server_org] = 'inception_llc'
#If this is set to nil, the configurator recipe will set it to the server_org.
default[:chef_server_populator][:default_org] = nil 
