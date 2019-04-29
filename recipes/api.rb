# Encoding: utf-8
#
# Cookbook Name:: openstack-bare-metal
# Recipe:: api
#
# Copyright 2015, IBM Corp.
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
end

include_recipe 'openstack-bare-metal::ironic-common'

platform_options = node['openstack']['bare_metal']['platform']

platform_options['ironic_api_packages'].each do |pkg|
  package pkg do
    action :upgrade

    notifies :restart, 'service[ironic-api]', :delayed
  end
end

service 'ironic-api' do
  service_name platform_options['ironic_api_service']
  action [:disable, :stop]
end

execute 'ironic db sync' do
  command 'ironic-dbsync --config-file /etc/ironic/ironic.conf upgrade'
  user 'root'
  group 'root'
  action :run
end

# remove the ironic-wsgi.conf automatically generated from package
apache_config 'ironic-wsgi' do
  enable false
end

bind_service = node['openstack']['bind_service']['all']['bare_metal']

web_app 'ironic-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'ironic-wsgi'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry '/usr/bin/ironic-api-wsgi'
  log_dir node['apache']['log_dir']
  run_dir node['apache']['run_dir']
  user node['openstack']['bare_metal']['user']
  group node['openstack']['bare_metal']['group']
  use_ssl node['openstack']['bare_metal']['ssl']['enabled']
  cert_file node['openstack']['bare_metal']['ssl']['certfile']
  chain_file node['openstack']['bare_metal']['ssl']['chainfile']
  key_file node['openstack']['bare_metal']['ssl']['keyfile']
  ca_certs_path node['openstack']['bare_metal']['ssl']['ca_certs_path']
  cert_required node['openstack']['bare_metal']['ssl']['cert_required']
  protocol node['openstack']['bare_metal']['ssl']['protocol']
  ciphers node['openstack']['bare_metal']['ssl']['ciphers']
end
