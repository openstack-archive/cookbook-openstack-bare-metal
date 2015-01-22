# encoding: UTF-8
#
# Cookbook Name:: openstack-bare-metal
# Attributes:: common-temp
#
# Copyright 2015, IBM, Corp
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

# TODO(wenchma) The following attributes are temporary workaround.
# These could be removed and replaced by the following patch once Kilo branch is created.
# https://review.openstack.org/#/c/148458/

# Database used by OpenStack Bare Metal (Ironic)
default['openstack']['db']['bare-metal']['service_type'] = node['openstack']['db']['service_type']
default['openstack']['db']['bare-metal']['host'] = node['openstack']['endpoints']['db']['host']
default['openstack']['db']['bare-metal']['port'] = node['openstack']['endpoints']['db']['port']
default['openstack']['db']['bare-metal']['db_name'] = 'ironic'
default['openstack']['db']['bare-metal']['username'] = 'ironic'
default['openstack']['db']['bare-metal']['options'] = node['openstack']['db']['options']

# Default attributes when not using data bags (use_databags = false)
%w{user service db token}.each do |type|
  default['openstack']['secret']['bare-metal'][type] = "bare-metal-#{type}"
end

qpid_defaults = {
  username: node['openstack']['mq']['user'],
  sasl_mechanisms: '',
  reconnect: true,
  reconnect_timeout: 0,
  reconnect_limit: 0,
  reconnect_interval_min: 0,
  reconnect_interval_max: 0,
  reconnect_interval: 0,
  heartbeat: 60,
  protocol: node['openstack']['mq']['qpid']['protocol'],
  tcp_nodelay: true,
  host: node['openstack']['endpoints']['mq']['host'],
  port: node['openstack']['endpoints']['mq']['port'],
  qpid_hosts: ["#{node['openstack']['endpoints']['mq']['host']}:#{node['openstack']['endpoints']['mq']['port']}"],
  topology_version: node['openstack']['mq']['qpid']['topology_version']
}

rabbit_defaults = {
  userid: node['openstack']['mq']['user'],
  vhost: node['openstack']['mq']['vhost'],
  port: node['openstack']['endpoints']['mq']['port'],
  host: node['openstack']['endpoints']['mq']['host'],
  ha: node['openstack']['mq']['rabbitmq']['ha'],
  use_ssl: node['openstack']['mq']['rabbitmq']['use_ssl']
}

default['openstack']['mq']['bare-metal']['service_type'] = node['openstack']['mq']['service_type']
default['openstack']['mq']['bare-metal']['notification_topic'] = 'notifications'

default['openstack']['mq']['bare-metal']['durable_queues'] =
  node['openstack']['mq']['durable_queues']
default['openstack']['mq']['bare-metal']['auto_delete'] =
  node['openstack']['mq']['auto_delete']

case node['openstack']['mq']['bare-metal']['service_type']
when 'qpid'
  qpid_defaults.each do |key, val|
    default['openstack']['mq']['bare-metal']['qpid'][key.to_s] = val
  end
when 'rabbitmq'
  rabbit_defaults.each do |key, val|
    default['openstack']['mq']['bare-metal']['rabbit'][key.to_s] = val
  end
end

default['openstack']['mq']['bare-metal']['qpid']['notification_topic'] =
  node['openstack']['mq']['bare-metal']['notification_topic']
default['openstack']['mq']['bare-metal']['rabbit']['notification_topic'] =
  node['openstack']['mq']['bare-metal']['notification_topic']
default['openstack']['mq']['bare-metal']['control_exchange'] = 'ironic'

# ******************** OpenStack Bare Metal Endpoints *****************************

# The OpenStack Bare Metal (Ironic) API endpoint
default['openstack']['endpoints']['bare-metal-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['bare-metal-api-bind']['port'] = '6385'
default['openstack']['endpoints']['bare-metal-api-bind']['bind_interface'] = nil

default['openstack']['endpoints']['bare-metal-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['bare-metal-api']['scheme'] = 'http'
default['openstack']['endpoints']['bare-metal-api']['port'] = '6385'
default['openstack']['endpoints']['bare-metal-api']['path'] = ''
default['openstack']['endpoints']['bare-metal-api']['bind_interface'] = nil
