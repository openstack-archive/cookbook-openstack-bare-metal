# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-bare-metal::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'bare-metal-stubs'

    it 'registers service tenant' do
      expect(chef_run).to create_tenant_openstack_identity_register(
        'Register Service Tenant'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        tenant_description: 'Service Tenant'
      )
    end

    it 'registers bare metal service' do
      expect(chef_run).to create_service_openstack_identity_register(
        'Register Ironic bare metal Service'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_name: 'ironic',
        service_type: 'baremetal',
        service_description: 'Ironic bare metal provisioning service'
      )
    end

    it 'registers bare metal endpoint' do
      expect(chef_run).to create_endpoint_openstack_identity_register(
        'Register Ironic bare metal Endpoint'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_type: 'baremetal',
        endpoint_region: 'RegionOne',
        endpoint_adminurl: 'http://127.0.0.1:6385',
        endpoint_internalurl: 'http://127.0.0.1:6385',
        endpoint_publicurl: 'http://127.0.0.1:6385'
      )
    end

    it 'registers bare metal service user' do
      expect(chef_run).to create_user_openstack_identity_register(
        'Register Ironic bare metal Service User'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        user_name: 'ironic',
        user_pass: 'service_pass'
      )
    end

    it 'grants admin role to service user for service tenant' do
      expect(chef_run).to grant_role_openstack_identity_register(
        'Grant admin Role to Ironic Service User for Ironic Service Tenant'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        role_name: 'admin',
        user_name: 'ironic'
      )
    end
  end
end
