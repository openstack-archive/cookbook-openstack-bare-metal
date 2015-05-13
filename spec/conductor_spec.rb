# Encoding: utf-8
#
# Cookbook Name:: openstack-bare-metal
# Spec:: conductor_spec
#
# Copyright 2015, IBM Corp.
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

require_relative 'spec_helper'

describe 'openstack-bare-metal::conductor' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'bare-metal-stubs'

    it 'includes ironic common recipe' do
      expect(chef_run).to include_recipe('openstack-bare-metal::ironic-common')
    end

    it 'upgrades ironic conductor packages' do
      %w(ironic-conductor shellinabox ipmitool).each do |pkg|
        expect(chef_run).to upgrade_package(pkg)
      end
    end

    describe 'ironic-conductor packages' do
      let(:package) { chef_run.package('ironic-conductor') }

      it 'sends a notification to the service' do
        expect(package).to notify('service[ironic-conductor]').to(:restart).delayed
      end
    end

    it 'enables ironic conductor on boot' do
      expect(chef_run).to enable_service('ironic-conductor')
    end

    describe 'ironic-conductor' do
      let(:service) { chef_run.service('ironic-conductor') }

      it 'subscribes to the template creation' do
        expect(service).to subscribe_to('template[/etc/ironic/ironic.conf]')
      end

      it 'subscribes to the common packages' do
        expect(service).to subscribe_to('package[python-ironicclient]').delayed
      end
    end
  end
end
