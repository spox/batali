if(node[:chef_server_populator][:default_org])
  node.default[:chef_server_populator][:chef_server][:configuration][:default_orgname] = node[:chef_server_populator][:default_org]
end

unless(node[:chef_server_populator][:endpoint])
  node.default[:chef_server_populator][:endpoint] = node[:chef_server_populator][:servername_override]
end

if(node[:chef_server_populator][:endpoint])
  node.set['chef-server'][:api_fqdn] =
    node.set[:chef_server_populator][:chef_server][:configuration][:nginx][:server_name] =
    node.set[:chef_server_populator][:chef_server][:configuration][:bookshelf][:vip] =
    node.set[:chef_server_populator][:chef_server][:configuration][:lb][:api_fqdn] =
    node.set[:chef_server_populator][:chef_server][:configuration][:lb][:web_ui_fqdn] = node[:chef_server_populator][:endpoint]
  node.set[:chef_server_populator][:chef_server][:configuration][:nginx][:url] =
    node.set[:chef_server_populator][:chef_server][:configuration][:bookshelf][:url] = "https://#{node[:chef_server_populator][:endpoint]}"
else
  node.set['chef-server'][:api_fqdn] =
    node.set[:chef_server_populator][:chef_server][:configuration][:nginx][:server_name] =
    node.set[:chef_server_populator][:chef_server][:configuration][:bookshelf][:vip] =
    node.set[:chef_server_populator][:chef_server][:configuration][:lb][:api_fqdn] =
    node.set[:chef_server_populator][:chef_server][:configuration][:lb][:web_ui_fqdn] = node[:fqdn]
  node.set[:chef_server_populator][:chef_server][:configuration][:nginx][:url] =
    node.set[:chef_server_populator][:chef_server][:configuration][:bookshelf][:url] = "https://#{node[:fqdn]}"
end

mash_maker = lambda do |x|
  if(x.is_a?(Hash))
    x = Mash.new(x)
    x.keys.each do |key|
      x[key] = mash_maker.call(x[key])
    end
  elsif(x.is_a?(Array))
    x = x.map do |value|
      mash_maker.call(value)
    end
  end
  x
end

current_server_config = mash_maker.call(node['chef-server'])
populator_server_config = mash_maker.call(node[:chef_server_populator][:chef_server] || {})

if(current_server_config[:configuration].is_a?(Hash))
  populator_server_config[:configuration] = Chef::Mixin::DeepMerge.deep_merge(
    current_server_config[:configuration],
    populator_server_config.fetch(:configuration, Mash.new)
  )
end

if(populator_server_config[:configuration])
  populator_server_config[:configuration] = populator_server_config[:configuration].map do |k,v|
    "#{k}(#{v.inspect})"
  end.join("\n")
end

current_server_config.delete(:configuration)

node.set['chef-server'] = Chef::Mixin::DeepMerge.deep_merge(
  current_server_config,
  populator_server_config
)

include_recipe 'chef-server'
