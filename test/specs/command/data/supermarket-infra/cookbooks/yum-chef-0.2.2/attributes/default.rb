#
# Author:: Joshua Timberman <joshua@chef.io>
# Copyright (c) 2015, Chef Software, Inc. <legal@chef.io>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.default['yum-chef'].tap do |yum|
  # The name of the repository, the configuration will be written to
  # /etc/yum/repos.d/repositoryid.repo
  yum['repositoryid']   = 'chef-stable'

  # The baseurl setting for the repository. This is calculated using the major
  # number part of the node's platform version. Must be a supported major version.
  # See https://docs.chef.io/supported_platforms.html
  yum['baseurl']        = "https://packagecloud.io/chef/stable/el/#{node['platform_version'].split('.').first}/$basearch"

  # Use the local copy of the Chef public GPG key if we're on a Chef Server.
  # This is to preserve compatibility with the `chef-server-ctl install` command.
  # Otherwise, retrieve the public key from Chef's downloads page.
  yum['gpgkey']         = if File.exist?('/opt/opscode/embedded/keys/packages-chef-io-public.key')
                            'file:///opt/opscode/embedded/keys/packages-chef-io-public.key'
                          else
                            'https://downloads.chef.io/packages-chef-io-public.key'
                          end

  # The path to the CA certificates used to verify SSL
  yum['sslcacert']      = '/etc/pki/tls/certs/ca-bundle.crt'

  # If a proxy is required, specify the URI as a string.
  # e.g., "http://proxy.example.com:3128"
  # Specify the username and password if required.
  yum['proxy']          = nil
  yum['proxy_username'] = nil
  yum['proxy_password'] = nil
end
