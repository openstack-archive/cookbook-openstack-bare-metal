# encoding: UTF-8
#
# Cookbook Name:: openstack-bare-metal
# Attributes:: default
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

# Set to some text value if you want templated config files
# to contain a custom banner at the top of the written file
default['openstack']['baremetal']['custom_template_banner'] = "
# This file is managed by Chef
# Do not edit, changes will be overwritten
"

%w(admin internal public).each do |ep_type|
  # host for openstack admin/internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['baremetal']['host'] = '127.0.0.1'
  # scheme for openstack admin/internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['baremetal']['scheme'] = 'http'
  # port for openstack admin/internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['baremetal']['port'] = 6385
  # path for openstack admin/internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['baremetal']['path'] = ''
end

default['openstack']['baremetal']['verbose'] = 'false'
default['openstack']['baremetal']['debug'] = 'false'

# Maximum number of worker threads that can be started
# simultaneously by a periodic task. Should be less than RPC
# thread pool size. (integer value)
default['openstack']['baremetal']['conductor']['periodic_max_workers'] = 8

# The size of the workers greenthread pool. (integer value)
default['openstack']['baremetal']['conductor']['workers_pool_size'] = 100

# Common rpc definitions
default['openstack']['baremetal']['rpc_thread_pool_size'] = 64
default['openstack']['baremetal']['rpc_conn_pool_size'] = 30
default['openstack']['baremetal']['rpc_response_timeout'] = 60

# The name of the Chef role that knows about the message queue server
# that Ironic uses
default['openstack']['baremetal']['rabbit_server_chef_role'] = 'os-ops-messaging'

default['openstack']['baremetal']['rpc_backend'] = 'rabbit'

# Logging stuff
default['openstack']['baremetal']['log_dir'] = '/var/log/ironic'

default['openstack']['baremetal']['syslog']['use'] = false
default['openstack']['baremetal']['syslog']['facility'] = 'LOG_LOCAL1'
default['openstack']['baremetal']['syslog']['config_facility'] = 'local1'

default['openstack']['baremetal']['region'] = node['openstack']['region']

# Keystone settings
default['openstack']['baremetal']['api']['auth_strategy'] = 'keystone'

default['openstack']['baremetal']['api']['auth']['version'] = node['openstack']['api']['auth']['version']

# Whether to allow the client to perform insecure SSL (https) requests
default['openstack']['baremetal']['api']['auth']['insecure'] = false

default['openstack']['baremetal']['service_user'] = 'ironic'
default['openstack']['baremetal']['project'] = 'service'
default['openstack']['baremetal']['service_role'] = 'service'
default['openstack']['baremetal']['service_name'] = 'ironic'
default['openstack']['baremetal']['service_type'] = 'baremetal'

default['openstack']['baremetal']['user'] = 'ironic'
default['openstack']['baremetal']['group'] = 'ironic'

# Setup the tftp variables
default['openstack']['baremetal']['tftp']['enabled'] = false
# IP address of Ironic compute node's tftp server
default['openstack']['baremetal']['tftp']['server'] = '127.0.0.1'
# Ironic compute node's tftp root path
default['openstack']['baremetal']['tftp']['root_path'] = '/var/lib/tftpboot'
# Directory where master tftp images are stored on disk
default['openstack']['baremetal']['tftp']['master_path'] = "#{node['openstack']['baremetal']['tftp']['root_path']}/master_images"

# Ironic WSGI app SSL settings
default['openstack']['baremetal']['ssl']['enabled'] = false
default['openstack']['baremetal']['ssl']['certfile'] = ''
default['openstack']['baremetal']['ssl']['chainfile'] = ''
default['openstack']['baremetal']['ssl']['keyfile'] = ''
default['openstack']['baremetal']['ssl']['ca_certs_path'] = ''
default['openstack']['baremetal']['ssl']['cert_required'] = false
default['openstack']['baremetal']['ssl']['protocol'] = ''
default['openstack']['baremetal']['ssl']['ciphers'] = ''

case node['platform_family']
when 'fedora', 'rhel'
  default['openstack']['baremetal']['platform'] = {
    'ironic_api_packages' => ['openstack-ironic-api'],
    'ironic_api_service' => 'openstack-ironic-api',
    'ironic_conductor_packages' => ['openstack-ironic-conductor', 'ipmitool'],
    'ironic_conductor_service' => 'openstack-ironic-conductor',
    'ironic_common_packages' => ['openstack-ironic-common', 'python-ironicclient'],
  }
when 'debian'
  default['openstack']['baremetal']['platform'] = {
    'ironic_api_packages' => ['ironic-api'],
    'ironic_api_service' => 'ironic-api',
    'ironic_conductor_packages' => ['ironic-conductor', 'ipmitool'],
    'ironic_conductor_service' => 'ironic-conductor',
    'ironic_common_packages' => ['python-ironicclient', 'ironic-common'],
  }
end

# ******************** OpenStack Bare Metal Endpoints *****************************

# The OpenStack Bare Metal (Ironic) API endpoint
%w(public internal admin).each do |ep_type|
  default['openstack']['endpoints'][ep_type]['baremetal']['scheme'] = 'http'
  default['openstack']['endpoints'][ep_type]['baremetal']['path'] = ''
  default['openstack']['endpoints'][ep_type]['baremetal']['host'] = '127.0.0.1'
  default['openstack']['endpoints'][ep_type]['baremetal']['port'] = '6385'
end
default['openstack']['bind_service']['all']['baremetal']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['baremetal']['port'] = '6385'
# ============================= rootwrap Configuration ===================
# use ironic root wrap
default['openstack']['baremetal']['use_rootwrap'] = true
# rootwrap.conf
default['openstack']['baremetal']['rootwrap']['conf'].tap do |conf|
  conf['DEFAULT']['filters_path'] = '/etc/ironic/rootwrap.d,/usr/share/ironic/rootwrap'
  conf['DEFAULT']['exec_dirs'] = '/sbin,/usr/sbin,/bin,/usr/bin'
  conf['DEFAULT']['use_syslog'] = false
  conf['DEFAULT']['syslog_log_facility'] = 'syslog'
  conf['DEFAULT']['syslog_log_level'] = 'ERROR'
end
