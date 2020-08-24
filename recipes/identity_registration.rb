# encoding: UTF-8
#
# Cookbook:: openstack-bare-metal
# Recipe:: identity_registration
#
# Copyright:: 2015, IBM, Inc.
# Copyright:: 2019-2020, Oregon State University
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

identity_endpoint = internal_endpoint 'identity'
auth_url = identity_endpoint.to_s

interfaces = {
  public: { url: public_endpoint('bare_metal') },
  internal: { url: internal_endpoint('bare_metal') },
}
service_pass = get_password 'service', 'openstack-bare-metal'
region = node['openstack']['bare_metal']['region']
service_project_name = node['openstack']['bare_metal']['conf']['keystone_authtoken']['project_name']
service_user = node['openstack']['bare_metal']['service_user']
admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', node['openstack']['identity']['admin_user']
admin_project = node['openstack']['identity']['admin_project']
admin_domain = node['openstack']['identity']['admin_domain_name']
# TODO(ramereth): commenting this out until
# https://github.com/fog/fog-openstack/pull/494 gets merged and released.
# endpoint_type = node['openstack']['identity']['endpoint_type']
service_domain_name = node['openstack']['bare_metal']['conf']['keystone_authtoken']['user_domain_name']
service_role = node['openstack']['bare_metal']['service_role']
service_name = node['openstack']['bare_metal']['service_name']
service_type = node['openstack']['bare_metal']['service_type']

connection_params = {
  openstack_auth_url: auth_url,
  openstack_username: admin_user,
  openstack_api_key: admin_pass,
  openstack_project_name: admin_project,
  openstack_domain_name: admin_domain,
  # openstack_endpoint_type: endpoint_type,
}

# Register Bare Metal Service
openstack_service service_name do
  type service_type
  connection_params connection_params
end

interfaces.each do |interface, res|
  # Register Bare Metal Endpoints
  openstack_endpoint service_type do
    service_name service_name
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Register Service Project
openstack_project service_project_name do
  connection_params connection_params
end

# Register Service User
openstack_user service_user do
  project_name service_project_name
  domain_name service_domain_name
  role_name service_role
  password service_pass
  connection_params connection_params
  action [:create, :grant_role]
end
