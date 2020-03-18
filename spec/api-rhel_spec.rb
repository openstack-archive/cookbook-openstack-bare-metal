# Encoding: utf-8

require_relative 'spec_helper'

describe 'openstack-bare-metal::api' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'bare-metal-stubs'

    it do
      expect(chef_run).to upgrade_package %w(openstack-ironic-api mod_wsgi)
    end

    it do
      expect(chef_run).to disable_service('ironic-api').with(service_name: 'openstack-ironic-api')
      expect(chef_run).to stop_service('ironic-api').with(service_name: 'openstack-ironic-api')
    end
  end
end
