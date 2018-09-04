# Encoding: utf-8
#
# Cookbook Name:: openstack-bare-metal
# Recipe:: ironic-common
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

if node['openstack']['baremetal']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['baremetal']['platform']

platform_options['ironic_common_packages'].each do |pkg|
  package pkg do
    action :upgrade
  end
end

db_type = node['openstack']['db']['baremetal']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    action :upgrade
  end
end

db_user = node['openstack']['db']['baremetal']['username']
db_pass = get_password 'db', 'ironic'

node.default['openstack']['baremetal']['conf_secrets']
  .[]('database')['connection'] =
  db_uri('baremetal', db_user, db_pass)
if node['openstack']['endpoints']['db']['enabled_slave']
  node.default['openstack']['baremetal']['conf_secrets']
    .[]('database')['slave_connection'] =
    db_uri('baremetal', db_user, db_pass, true)
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['baremetal']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'baremetal'
end

# merge all config options and secrets to be used in ironic.conf
ironic_conf_options = merge_config_options 'baremetal'

directory '/etc/ironic' do
  owner node['openstack']['baremetal']['user']
  group node['openstack']['baremetal']['group']
  mode 00750
  action :create
end

template '/etc/ironic/ironic.conf' do
  source 'ironic.conf.erb'
  owner node['openstack']['baremetal']['user']
  group node['openstack']['baremetal']['group']
  mode 00640
  variables(
    service_config: ironic_conf_options
  )
end

# delete all secrets saved in the attribute
# node['openstack']['baremetal']['conf_secrets'] after creating the config file
ruby_block "delete all attributes in node['openstack']['baremetal']['conf_secrets']" do
  block do
    node.rm(:openstack, :baremetal, :conf_secrets)
  end
end

if node['openstack']['baremetal']['use_rootwrap']
  template '/etc/ironic/rootwrap.conf' do
    source 'openstack-service.conf.erb'
    cookbook 'openstack-common'
    owner 'root'
    group 'root'
    mode 0o0644
    variables(
      service_config: node['openstack']['baremetal']['rootwrap']['conf']
    )
  end
end
