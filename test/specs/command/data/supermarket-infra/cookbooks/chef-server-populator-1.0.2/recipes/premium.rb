# Warning: Enable Premium Features at your own risk, as they may cost $$$
# https://www.chef.io/chef/#plans-and-pricing

node[:chef_server_populator][:premium].each do |feature, settings|
  execute "install_#{feature}" do
    command "chef-server-ctl install opscode-#{feature}"
    only_if settings[:enabled]
  end

  #Let's make 3 config files for each feature, as the naming is inconsistent

  short_name = feature.split('-').drop(1).join('-')
  %w( "chef-#{short_name}" "opscode-#{short_name}" short_name ).each do |conf|
    file "/etc/#{feature}/#{conf}.rb" do
      content ''
      only_if settings[:enabled]
      notifies :run, "execute[:configure_#{feature}]", :delayed
    end
  end

  execute "configure_#{feature}" do
    command "#{feature}-ctl reconfigure"
    action :nothing
    notifies :run, "execute[:reconfigure_chef_server]", :delayed
  end
end

execute "reconfigure_chef_server" do
  command 'chef-server-ctl reconfigure'
  action :nothing
end
