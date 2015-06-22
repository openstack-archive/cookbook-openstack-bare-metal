# encoding: UTF-8
#
# Cookbook Name:: openstack-bare-metal
# Recipe:: identity_registration
#
# Copyright 2015, IBM, Inc.
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

require 'uri'

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

identity_admin_endpoint = endpoint 'identity-admin'
bootstrap_token = get_password 'token', 'openstack_identity_bootstrap_token'
auth_uri = ::URI.decode identity_admin_endpoint.to_s
ironic_api_endpoint = endpoint 'bare-metal-api'
service_pass = get_password 'service', 'openstack-bare-metal'
region = node['openstack']['bare-metal']['region']
service_tenant_name = node['openstack']['bare-metal']['service_tenant_name']
service_user = node['openstack']['bare-metal']['service_user']
service_role = node['openstack']['bare-metal']['service_role']

openstack_identity_register 'Register Service Tenant' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  tenant_description 'Service Tenant'

  action :create_tenant
end

openstack_identity_register 'Register Ironic bare metal Service' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_name 'ironic'
  service_type 'baremetal'
  service_description 'Ironic bare metal provisioning service'

  action :create_service
end

openstack_identity_register 'Register Ironic bare metal Endpoint' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_type 'baremetal'
  endpoint_region region
  endpoint_adminurl ::URI.decode ironic_api_endpoint.to_s
  endpoint_internalurl ::URI.decode ironic_api_endpoint.to_s
  endpoint_publicurl ::URI.decode ironic_api_endpoint.to_s

  action :create_endpoint
end

openstack_identity_register 'Register Ironic bare metal Service User' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  user_name service_user
  user_pass service_pass

  action :create_user
end

openstack_identity_register 'Grant admin Role to Ironic Service User for Ironic Service Tenant' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  user_name service_user
  role_name service_role

  action :grant_role
end
