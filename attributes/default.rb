#
# Cookbook:: openstack-bare-metal
# Attributes:: default
#
# Copyright:: 2015-2021, IBM, Corp
# Copyright:: 2019-2021, Oregon State University
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
default['openstack']['bare_metal']['custom_template_banner'] = "
# This file is managed by Chef
# Do not edit, changes will be overwritten
"

%w(internal public).each do |ep_type|
  # host for openstack internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['bare_metal']['host'] = '127.0.0.1'
  # scheme for openstack internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['bare_metal']['scheme'] = 'http'
  # port for openstack internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['bare_metal']['port'] = 6385
  # path for openstack internal/public bare metal endpoint
  default['openstack']['endpoints'][ep_type]['bare_metal']['path'] = ''
end

default['openstack']['bare_metal']['verbose'] = 'false'
default['openstack']['bare_metal']['debug'] = 'false'

# Maximum number of worker threads that can be started
# simultaneously by a periodic task. Should be less than RPC
# thread pool size. (integer value)
default['openstack']['bare_metal']['conductor']['periodic_max_workers'] = 8

# The size of the workers greenthread pool. (integer value)
default['openstack']['bare_metal']['conductor']['workers_pool_size'] = 100

# Common rpc definitions
default['openstack']['bare_metal']['rpc_thread_pool_size'] = 64
default['openstack']['bare_metal']['rpc_conn_pool_size'] = 30
default['openstack']['bare_metal']['rpc_response_timeout'] = 60

# The name of the Chef role that knows about the message queue server
# that Ironic uses
default['openstack']['bare_metal']['rabbit_server_chef_role'] = 'os-ops-messaging'

default['openstack']['bare_metal']['rpc_backend'] = 'rabbit'

# Logging stuff
default['openstack']['bare_metal']['log_dir'] = '/var/log/ironic'

default['openstack']['bare_metal']['syslog']['use'] = false
default['openstack']['bare_metal']['syslog']['facility'] = 'LOG_LOCAL1'
default['openstack']['bare_metal']['syslog']['config_facility'] = 'local1'

default['openstack']['bare_metal']['region'] = node['openstack']['region']

# Keystone settings
default['openstack']['bare_metal']['api']['auth_strategy'] = 'keystone'

# Whether to allow the client to perform insecure SSL (https) requests
default['openstack']['bare_metal']['api']['auth']['insecure'] = false

default['openstack']['bare_metal']['service_user'] = 'ironic'
default['openstack']['bare_metal']['project'] = 'service'
default['openstack']['bare_metal']['service_role'] = 'service'
default['openstack']['bare_metal']['service_name'] = 'ironic'
default['openstack']['bare_metal']['service_type'] = 'bare_metal'

default['openstack']['bare_metal']['user'] = 'ironic'
default['openstack']['bare_metal']['group'] = 'ironic'

# Setup the tftp variables
default['openstack']['bare_metal']['tftp']['enabled'] = false
# IP address of Ironic compute node's tftp server
default['openstack']['bare_metal']['tftp']['server'] = '127.0.0.1'
# Ironic compute node's tftp root path
default['openstack']['bare_metal']['tftp']['root_path'] = '/var/lib/tftpboot'
# Directory where master tftp images are stored on disk
default['openstack']['bare_metal']['tftp']['master_path'] = "#{node['openstack']['bare_metal']['tftp']['root_path']}/master_images"

# Ironic WSGI app SSL settings
default['openstack']['bare_metal']['ssl']['enabled'] = false
default['openstack']['bare_metal']['ssl']['certfile'] = ''
default['openstack']['bare_metal']['ssl']['chainfile'] = ''
default['openstack']['bare_metal']['ssl']['keyfile'] = ''
default['openstack']['bare_metal']['ssl']['ca_certs_path'] = ''
default['openstack']['bare_metal']['ssl']['cert_required'] = false
default['openstack']['bare_metal']['ssl']['protocol'] = ''
default['openstack']['bare_metal']['ssl']['ciphers'] = ''

case node['platform_family']
when 'fedora', 'rhel'
  default['openstack']['bare_metal']['platform'] = {
    'ironic_api_packages' => %w(openstack-ironic-api),
    'ironic_api_service' => 'openstack-ironic-api',
    'ironic_conductor_packages' => %w(openstack-ironic-conductor ipmitool),
    'ironic_conductor_service' => 'openstack-ironic-conductor',
    'ironic_common_packages' => node['platform_version'].to_i >= 8 ? %w(openstack-ironic-common python3-ironicclient) : %w(openstack-ironic-common python-ironicclient),
  }
when 'debian'
  default['openstack']['bare_metal']['platform'] = {
    'ironic_api_packages' => ['ironic-api'],
    'ironic_api_service' => 'ironic-api',
    'ironic_conductor_packages' => %w(ironic-conductor ipmitool),
    'ironic_conductor_service' => 'ironic-conductor',
    'ironic_common_packages' =>
      %w(
        python3-ironic
        python3-ironic-lib
        python3-ironicclient
        ironic-common
      ),
  }
end

# ******************** OpenStack Bare Metal Endpoints *****************************

# The OpenStack Bare Metal (Ironic) API endpoint
%w(public internal).each do |ep_type|
  default['openstack']['endpoints'][ep_type]['bare_metal']['scheme'] = 'http'
  default['openstack']['endpoints'][ep_type]['bare_metal']['path'] = ''
  default['openstack']['endpoints'][ep_type]['bare_metal']['host'] = '127.0.0.1'
  default['openstack']['endpoints'][ep_type]['bare_metal']['port'] = '6385'
end
default['openstack']['bind_service']['all']['bare_metal']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['bare_metal']['port'] = '6385'
# ============================= rootwrap Configuration ===================
# use ironic root wrap
default['openstack']['bare_metal']['use_rootwrap'] = true
# rootwrap.conf
default['openstack']['bare_metal']['rootwrap']['conf'].tap do |conf|
  conf['DEFAULT']['filters_path'] = '/etc/ironic/rootwrap.d,/usr/share/ironic/rootwrap'
  conf['DEFAULT']['exec_dirs'] = '/sbin,/usr/sbin,/bin,/usr/bin'
  conf['DEFAULT']['use_syslog'] = false
  conf['DEFAULT']['syslog_log_facility'] = 'syslog'
  conf['DEFAULT']['syslog_log_level'] = 'ERROR'
end
