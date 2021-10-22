require_relative 'spec_helper'

describe 'openstack-bare-metal::ironic-common' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'bare-metal-stubs'

      case p
      when REDHAT_7
        it do
          expect(chef_run).to upgrade_package %w(openstack-ironic-common python-ironicclient)
        end
      when REDHAT_8
        it do
          expect(chef_run).to upgrade_package %w(openstack-ironic-common python3-ironicclient)
        end
      end
    end
  end
end
