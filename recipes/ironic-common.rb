# Encoding: utf-8
#
# Cookbook:: openstack-bare-metal
# Recipe:: ironic-common
#
# Copyright:: 2015, IBM Corp.
# Copyright:: 2020, Oregon State University
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

if node['openstack']['bare_metal']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['bare_metal']['platform']

package platform_options['ironic_common_packages'] do
  action :upgrade
end

db_type = node['openstack']['db']['bare_metal']['service_type']
package node['openstack']['db']['python_packages'][db_type] do
  action :upgrade
end

db_user = node['openstack']['db']['bare_metal']['username']
db_pass = get_password 'db', 'ironic'

node.default['openstack']['bare_metal']['conf_secrets']
  .[]('database')['connection'] =
  db_uri('bare_metal', db_user, db_pass)
if node['openstack']['endpoints']['db']['enabled_slave']
  node.default['openstack']['bare_metal']['conf_secrets']
    .[]('database')['slave_connection'] =
    db_uri('bare_metal', db_user, db_pass, true)
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['bare_metal']['conf_secrets']['DEFAULT']['transport_url'] =
    rabbit_transport_url 'bare_metal'
end

identity_endpoint = internal_endpoint 'identity'
node.default['openstack']['bare_metal']['conf_secrets']
  .[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-bare-metal'
auth_url = identity_endpoint.to_s

node.default['openstack']['bare_metal']['conf'].tap do |conf|
  conf['keystone_authtoken']['auth_url'] = auth_url
end

# merge all config options and secrets to be used in ironic.conf
ironic_conf_options = merge_config_options 'bare_metal'

directory '/etc/ironic' do
  owner node['openstack']['bare_metal']['user']
  group node['openstack']['bare_metal']['group']
  mode '750'
end

template '/etc/ironic/ironic.conf' do
  source 'ironic.conf.erb'
  owner node['openstack']['bare_metal']['user']
  group node['openstack']['bare_metal']['group']
  sensitive true
  mode '640'
  variables(
    service_config: ironic_conf_options
  )
end

# delete all secrets saved in the attribute
# node['openstack']['bare_metal']['conf_secrets'] after creating the config file
ruby_block "delete all attributes in node['openstack']['bare_metal']['conf_secrets']" do
  block do
    node.rm(:openstack, :bare_metal, :conf_secrets)
  end
end

if node['openstack']['bare_metal']['use_rootwrap']
  template '/etc/ironic/rootwrap.conf' do
    source 'openstack-service.conf.erb'
    cookbook 'openstack-common'
    owner 'root'
    group 'root'
    mode '644'
    variables(
      service_config: node['openstack']['bare_metal']['rootwrap']['conf']
    )
  end
end
