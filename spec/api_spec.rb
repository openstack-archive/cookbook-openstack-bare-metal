# Encoding: utf-8
#
# Cookbook Name:: openstack-bare-metal
# Spec:: api_spec
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

describe 'openstack-bare-metal::api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'bare-metal-stubs'

    it 'includes ironic common recipe' do
      expect(chef_run).to include_recipe('openstack-bare-metal::ironic-common')
    end

    it 'upgrades ironic api packages' do
      expect(chef_run).to upgrade_package('ironic-api')
    end

    it 'disables ironic api on boot' do
      expect(chef_run).to disable_service('ironic-api')
    end

    it 'runs db migrations' do
      expect(chef_run).to run_execute('ironic db sync').with(user: 'root', group: 'root')
    end
  end
end
