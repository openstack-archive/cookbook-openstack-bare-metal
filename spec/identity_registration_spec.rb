require_relative 'spec_helper'

describe 'openstack-bare-metal::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'bare-metal-stubs'

    connection_params = {
      openstack_auth_url: 'http://127.0.0.1:5000/v3',
      openstack_username: 'admin',
      openstack_api_key: 'admin_test_pass',
      openstack_project_name: 'admin',
      openstack_domain_name: 'default',
      # openstack_endpoint_type: 'internalURL',
    }
    service_name = 'bare_metal'
    service_project = 'ironic'
    service_user = 'ironic'

    it "registers #{service_name} service" do
      expect(chef_run).to create_openstack_service(
        service_project
      ).with(
        connection_params: connection_params
      )
    end

    it "registers #{service_name} endpoint" do
      expect(chef_run).to create_openstack_endpoint(
        service_name
      ).with(
        connection_params: connection_params
      )
    end

    it "registers #{service_name} user" do
      expect(chef_run).to create_openstack_user(
        service_user
      ).with(
        connection_params: connection_params
      )
    end
  end
end
