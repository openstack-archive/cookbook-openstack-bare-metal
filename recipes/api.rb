#
# Cookbook:: openstack-bare-metal
# Recipe:: api
#
# Copyright:: 2015-2021, IBM Corp.
# Copyright:: 2020-2021, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class ::Chef::Recipe
  include ::Openstack
  include Apache2::Cookbook::Helpers
end

include_recipe 'openstack-bare-metal::ironic-common'

platform_options = node['openstack']['bare_metal']['platform']

package platform_options['ironic_api_packages'] do
  action :upgrade
end

service 'ironic-api' do
  service_name platform_options['ironic_api_service']
  action [:disable, :stop]
end

execute 'ironic db sync' do
  command 'ironic-dbsync --config-file /etc/ironic/ironic.conf upgrade'
  user 'root'
  group 'root'
end

# remove the ironic-wsgi.conf automatically generated from package
apache2_conf 'ironic-wsgi' do
  action :disable
end

bind_service = node['openstack']['bind_service']['all']['bare_metal']

# Finds and appends the listen port to the apache2_install[openstack]
# resource which is defined in openstack-identity::server-apache.
apache_resource = find_resource(:apache2_install, 'openstack')

if apache_resource
  apache_resource.listen = [apache_resource.listen, "#{bind_service['host']}:#{bind_service['port']}"].flatten
else
  apache2_install 'openstack' do
    listen "#{bind_service['host']}:#{bind_service['port']}"
  end
end

# service['apache2'] is defined in the apache2_default_install resource
# but other resources are currently unable to reference it.  To work
# around this issue, define the following helper in your cookbook:
service 'apache2' do
  extend Apache2::Cookbook::Helpers
  service_name lazy { apache_platform_service_name }
  supports restart: true, status: true, reload: true
  action :nothing
end

apache2_mod_wsgi 'bare-metal'
apache2_module 'ssl' if node['openstack']['bare_metal']['ssl']['enabled']

template "#{apache_dir}/sites-available/ironic-api.conf" do
  extend Apache2::Cookbook::Helpers
  source 'wsgi-template.conf.erb'
  variables(
    daemon_process: 'ironic-wsgi',
    server_host: bind_service['host'],
    server_port: bind_service['port'],
    server_entry: '/usr/bin/ironic-api-wsgi',
    log_dir: default_log_dir,
    run_dir: lock_dir,
    user: node['openstack']['bare_metal']['user'],
    group: node['openstack']['bare_metal']['group']
  )
  notifies :restart, 'service[apache2]'
end

apache2_site 'ironic-api' do
  notifies :restart, 'service[apache2]', :immediately
end
