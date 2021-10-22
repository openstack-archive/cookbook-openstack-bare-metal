require_relative 'spec_helper'

describe 'openstack-bare-metal::conductor' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'bare-metal-stubs'

      it do
        expect(chef_run).to upgrade_package %w(openstack-ironic-conductor ipmitool)
      end
    end
  end
end
