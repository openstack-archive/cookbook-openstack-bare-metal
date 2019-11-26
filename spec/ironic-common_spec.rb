# Encoding: utf-8
#
# Cookbook Name:: openstack-bare-metal
# Spec:: ironic_common_spec
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

describe 'openstack-bare-metal::ironic-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'bare-metal-stubs'

    it 'upgrades ironic common packages' do
      expect(chef_run).to upgrade_package('ironic-common')
      expect(chef_run).to upgrade_package('python3-ironic')
      expect(chef_run).to upgrade_package('python3-ironic-lib')
      expect(chef_run).to upgrade_package('python3-ironicclient')
    end

    describe '/etc/ironic' do
      let(:dir) { chef_run.directory('/etc/ironic') }

      it 'should create the /etc/ironic directory' do
        expect(chef_run).to create_directory(dir.name).with(
          user: 'ironic',
          group: 'ironic',
          mode: 0o0750
        )
      end
    end

    describe 'ironic.conf' do
      let(:file) { chef_run.template('/etc/ironic/ironic.conf') }
      let(:test_pass) { 'test_pass' }
      before do
        allow_any_instance_of(Chef::Recipe).to receive(:get_password)
          .with('user', anything)
          .and_return(test_pass)
      end

      it 'should create the ironic.conf template' do
        expect(chef_run).to create_template(file.name).with(
          user: 'ironic',
          group: 'ironic',
          mode: 0o0640
        )
      end

      context 'template contents' do
        context 'syslog use' do
          it 'sets the log_config value when syslog is in use' do
            node.override['openstack']['bare_metal']['syslog']['use'] = true

            expect(chef_run).to render_file(file.name)
              .with_content(%r{^log_config = /etc/openstack/logging.conf$})
          end
        end

        it 'has a db connection attribute' do
          allow_any_instance_of(Chef::Recipe).to receive(:db_uri)
            .and_return('sql_connection_value')

          expect(chef_run).to render_config_file(file.name)
            .with_section_content('database', /^connection = sql_connection_value$/)
        end
      end
    end

    describe 'rootwrap.conf' do
      let(:file) { chef_run.template('/etc/ironic/rootwrap.conf') }

      it 'should create the /etc/ironic/rootwrap.conf file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 0o644
        )
      end

      context 'template contents' do
        it 'sets the default attributes' do
          [
            %r{^filters_path = /etc/ironic/rootwrap.d,/usr/share/ironic/rootwrap$},
            %r{^exec_dirs = /sbin,/usr/sbin,/bin,/usr/bin$},
            /^use_syslog = false$/,
            /^syslog_log_facility = syslog$/,
            /^syslog_log_level = ERROR$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_content(line)
          end
        end
      end
    end
  end
end
