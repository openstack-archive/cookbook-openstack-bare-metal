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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

include_recipe 'openstack-bare-metal::ironic-common'

platform_options = node['openstack']['bare-metal']['platform']

platform_options['ironic_api_packages'].each do |pkg|
  package pkg do
    action :upgrade

    notifies :restart, 'service[ironic-api]', :delayed
  end
end

directory '/var/cache/ironic' do
  owner node['openstack']['bare-metal']['user']
  group node['openstack']['bare-metal']['group']
  mode 00700
  action :create
end

service 'ironic-api' do
  service_name platform_options['ironic_api_service']
  supports status: true, restart: true

  action [:enable]

  subscribes :restart, 'template[/etc/ironic/ironic.conf]'

  platform_options['ironic_common_packages'].each do |pkg|
    subscribes :restart, "package[#{pkg}]", :delayed
  end
end

execute 'ironic db sync' do
  command 'ironic-dbsync --config-file /etc/ironic/ironic.conf upgrade'
  user 'root'
  group 'root'
  action :run
end
