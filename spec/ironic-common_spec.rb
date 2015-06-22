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

      it 'has the default api attributes' do
        [
          /^host_ip=127.0.0.1$/,
          /^port=6385$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('api', line)
        end
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

      it 'has the default conductor attributes' do
        [
          /^periodic_max_workers=8$/,
          /^workers_pool_size=100$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('conductor', line)
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
            %r{^signing_dir=/var/cache/ironic/api$},
            %r{^auth_uri=http://127.0.0.1:5000/v2.0$},
            %r{^identity_uri=http://127.0.0.1:35357/$},
            /^auth_version=v2.0$/,
            /^admin_user=ironic$/,
            /^admin_password=service_pass$/,
            /^admin_tenant_name=service$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('keystone_authtoken', line)
          end
        end
      end

      it 'has default neutron attributes' do
        expect(chef_run).to render_config_file(file.name).with_section_content('neutron', %r{^url=http://127.0.0.1:9696$})
      end

      context 'tftp' do
        before do
          node.set['openstack']['bare-metal']['tftp']['enabled'] = true
        end

        it 'sets tftp attributes' do
          [
            /^tftp_server=127.0.0.1$/,
            %r{^tftp_root=/var/lib/tftpboot$},
            %r{^tftp_master_path=/var/lib/tftpboot/master_images$}
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('pxe', line)
          end
        end
      end

      context 'qpid as mq service' do
        before do
          node.set['openstack']['mq']['bare-metal']['service_type'] = 'qpid'
        end

        it 'has default RPC/AMQP options set' do
          [/^rpc_conn_pool_size=30$/,
           /^amqp_durable_queues=false$/,
           /^amqp_auto_delete=false$/].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', line)
          end
        end

        %w(port username sasl_mechanisms reconnect reconnect_timeout reconnect_limit
           reconnect_interval_min reconnect_interval_max reconnect_interval heartbeat protocol
           tcp_nodelay).each do |attr|
          it "has qpid_#{attr} attribute" do
            node.set['openstack']['mq']['bare-metal']['qpid'][attr] = "qpid_#{attr}_value"
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_#{attr}=qpid_#{attr}_value$/)
          end
        end

        it 'has qpid_hostname' do
          node.set['openstack']['mq']['bare-metal']['qpid']['host'] = 'qpid_host_value'
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_hostname=qpid_host_value$/)
        end

        it 'has qpid_password' do
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_password=user_pass$/)
        end

        it 'has default qpid topology version' do
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_topology_version=1$/)
        end
      end

      context 'rabbit mq backend' do
        before do
          node.set['openstack']['mq']['bare-metal']['service_type'] = 'rabbitmq'
        end

        it 'has default RPC/AMQP options set' do
          [/^rpc_conn_pool_size=30$/,
           /^amqp_durable_queues=false$/,
           /^amqp_auto_delete=false$/,
           /^heartbeat_timeout_threshold=0$/,
           /^heartbeat_rate=2$/].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end

        it 'does not have ssl config set' do
          [/^rabbit_use_ssl=/,
           /^kombu_ssl_version=/,
           /^kombu_ssl_keyfile=/,
           /^kombu_ssl_certfile=/,
           /^kombu_ssl_ca_certs=/,
           /^kombu_reconnect_delay=/,
           /^kombu_reconnect_timeout=/].each do |line|
            expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end

        it 'sets ssl config' do
          node.set['openstack']['mq']['bare-metal']['rabbit']['use_ssl'] = true
          node.set['openstack']['mq']['bare-metal']['rabbit']['kombu_ssl_version'] = 'TLSv1.2'
          node.set['openstack']['mq']['bare-metal']['rabbit']['kombu_ssl_keyfile'] = 'keyfile'
          node.set['openstack']['mq']['bare-metal']['rabbit']['kombu_ssl_certfile'] = 'certfile'
          node.set['openstack']['mq']['bare-metal']['rabbit']['kombu_ssl_ca_certs'] = 'certsfile'
          node.set['openstack']['mq']['bare-metal']['rabbit']['kombu_reconnect_delay'] = 123.123
          node.set['openstack']['mq']['bare-metal']['rabbit']['kombu_reconnect_timeout'] = 123
          [/^rabbit_use_ssl=true/,
           /^kombu_ssl_version=TLSv1.2$/,
           /^kombu_ssl_keyfile=keyfile$/,
           /^kombu_ssl_certfile=certfile$/,
           /^kombu_ssl_ca_certs=certsfile$/,
           /^kombu_reconnect_delay=123.123$/,
           /^kombu_reconnect_timeout=123$/].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end

        context 'ha attributes' do
          before do
            node.set['openstack']['mq']['bare-metal']['rabbit']['ha'] = true
          end

          it 'has a rabbit_hosts attribute' do
            allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
              .and_return('rabbit_servers_value')

            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_hosts=rabbit_servers_value$/)
          end

          %w(host port).each do |attr|
            it "does not have rabbit_#{attr} attribute" do
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_#{attr}=/)
            end
          end
        end

        context 'non ha attributes' do
          before do
            node.set['openstack']['mq']['bare-metal']['rabbit']['ha'] = false
          end

          %w(host port).each do |attr|
            it "has rabbit_#{attr} attribute" do
              node.set['openstack']['mq']['bare-metal']['rabbit'][attr] = "rabbit_#{attr}_value"
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_#{attr}=rabbit_#{attr}_value$/)
            end
          end

          it 'does not have a rabbit_hosts attribute' do
            expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_hosts=/)
          end
        end

        it 'has rabbit_userid' do
          node.set['openstack']['mq']['bare-metal']['rabbit']['userid'] = 'rabbit_userid_value'
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_userid=rabbit_userid_value$/)
        end

        it 'has rabbit_password' do
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_password=user_pass$/)
        end

        it 'has rabbit_virtual_host' do
          node.set['openstack']['mq']['bare-metal']['rabbit']['vhost'] = 'vhost_value'
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_virtual_host=vhost_value$/)
        end

        it 'has the default rabbit_retry_interval set' do
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_retry_interval=1$/)
        end

        it 'has the default rabbit_max_retries set' do
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_max_retries=0$/)
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
            %r{^filters_path=/etc/ironic/rootwrap.d,/usr/share/ironic/rootwrap$},
            %r{^exec_dirs=/sbin,/usr/sbin,/bin,/usr/bin$},
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
