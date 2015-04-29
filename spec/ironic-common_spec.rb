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
      expect(chef_run).to upgrade_package('python-ironicclient')
      expect(chef_run).to upgrade_package('ironic-common')
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('python-mysqldb')
    end

    describe '/etc/ironic' do
      let(:dir) { chef_run.directory('/etc/ironic') }

      it 'should create the directory' do
        expect(chef_run).to create_directory(dir.name).with(
          user: 'ironic',
          group: 'ironic',
          mode: 0750
        )
      end
    end

    describe 'ironic.conf' do
      let(:file) { chef_run.template('/etc/ironic/ironic.conf') }

      it 'should create the ironic.conf template' do
        expect(chef_run).to create_template(file.name).with(
          user: 'ironic',
          group: 'ironic',
          mode: 0640
        )
      end

      it 'has the default glance attributes' do
        [
          /^glance_host=127.0.0.1$/,
          /^glance_port=9292$/,
          /^glance_protocol=http$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('glance', line)
        end
      end

      context 'template contents' do
        it 'has the default rpc_backend attribute' do
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^rpc_backend=rabbit$/)
        end

        it 'overrides the default rpc_backend attribute' do
          node.set['openstack']['bare-metal']['rpc_backend'] = 'qpid'

          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^rpc_backend=qpid$/)
        end

        it 'sets the default auth attributes' do
          [
            /^insecure=false$/,
            %r(^signing_dir=/var/cache/ironic/api$),
            %r(^auth_uri=http://127.0.0.1:5000/v2.0$),
            %r(^identity_uri=http://127.0.0.1:35357/$),
            /^auth_version=v2.0$/,
            /^admin_user=ironic$/,
            /^admin_password=service_pass$/,
            /^admin_tenant_name=service$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('keystone_authtoken', line)
          end
        end
      end

      context 'tftp' do
        before do
          node.set['openstack']['bare-metal']['tftp']['enabled'] = true
        end

        it 'sets tftp attributes' do
          [
            /^tftp_server=127.0.0.1$/,
            %r(^tftp_root=/var/lib/tftpboot$),
            %r(^tftp_master_path=/var/lib/tftpboot/master_images$)
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('pxe', line)
          end
        end
      end

      context 'rabbit mq backend' do
        before do
          node.set['openstack']['mq']['bare-metal']['service_type'] = 'rabbitmq'
        end

        it 'does not have kombu ssl version set' do
          expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', /^kombu_ssl_version=TLSv1.2$/)
        end

        it 'sets kombu ssl version' do
          node.set['openstack']['mq']['bare-metal']['rabbit']['use_ssl'] = true
          node.set['openstack']['mq']['bare-metal']['rabbit']['kombu_ssl_version'] = 'TLSv1.2'

          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^kombu_ssl_version=TLSv1.2$/)
        end
      end
    end

    describe 'rootwrap.conf' do
      let(:file) { chef_run.template('/etc/ironic/rootwrap.conf') }

      it 'should create the /etc/ironic/rootwrap.conf file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 0644
        )
      end

      context 'template contents' do
        it 'shows the custom banner' do
          node.set['openstack']['bare-metal']['custom_template_banner'] = 'banner'

          expect(chef_run).to render_file(file.name).with_content(/^banner$/)
        end

        it 'sets the default attributes' do
          [
            %r(^filters_path=/etc/ironic/rootwrap.d,/usr/share/ironic/rootwrap$),
            %r(^exec_dirs=/sbin,/usr/sbin,/bin,/usr/bin$),
            /^use_syslog=false$/,
            /^syslog_log_facility=syslog$/,
            /^syslog_log_level=ERROR$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
          end
        end
      end
    end
  end
end
