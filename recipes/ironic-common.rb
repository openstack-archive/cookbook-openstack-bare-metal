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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

if node['openstack']['bare-metal']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['bare-metal']['platform']

platform_options['ironic_common_packages'].each do |pkg|
  package pkg do
    action :upgrade
  end
end

db_type = node['openstack']['db']['bare-metal']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    action :upgrade
  end
end

directory '/etc/ironic' do
  owner node['openstack']['bare-metal']['user']
  group node['openstack']['bare-metal']['group']
  mode 00750
  action :create
end

db_user = node['openstack']['db']['bare-metal']['username']
db_pass = get_password 'db', 'ironic'
db_connection = db_uri('bare-metal', db_user, db_pass)

mq_service_type = node['openstack']['mq']['bare-metal']['service_type']

if mq_service_type == 'rabbitmq'
  node['openstack']['mq']['bare-metal']['rabbit']['ha'] && (rabbit_hosts = rabbit_servers)
  mq_password = get_password 'user', node['openstack']['mq']['bare-metal']['rabbit']['userid']
elsif mq_service_type == 'qpid'
  mq_password = get_password 'user', node['openstack']['mq']['bare-metal']['qpid']['username']
end

image_endpoint = endpoint 'image-api'

identity_endpoint = internal_endpoint 'identity-internal'
identity_admin_endpoint = admin_endpoint 'identity-admin'
service_pass = get_password 'service', 'openstack-bare-metal'

auth_uri = auth_uri_transform(identity_endpoint.to_s, node['openstack']['bare-metal']['api']['auth']['version'])
identity_uri = identity_uri_transform(identity_admin_endpoint)

network_endpoint = internal_endpoint 'network-api' || {}
api_bind = internal_endpoint 'bare-metal-api-bind'

template '/etc/ironic/ironic.conf' do
  source 'ironic.conf.erb'
  owner node['openstack']['bare-metal']['user']
  group node['openstack']['bare-metal']['group']
  mode 00640
  variables(
    api_bind_address: api_bind.host,
    api_bind_port: api_bind.port,
    db_connection: db_connection,
    mq_service_type: mq_service_type,
    mq_password: mq_password,
    rabbit_hosts: rabbit_hosts,
    network_endpoint: network_endpoint,
    glance_protocol: image_endpoint.scheme,
    glance_host: image_endpoint.host,
    glance_port: image_endpoint.port,
    auth_uri: auth_uri,
    identity_uri: identity_uri,
    service_pass: service_pass
  )
end

template '/etc/ironic/rootwrap.conf' do
  source 'rootwrap.conf.erb'
  # Must be root!
  owner 'root'
  group 'root'
  mode 00644
end
