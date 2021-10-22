#
# Cookbook:: openstack-bare-metal
# Spec:: api_spec
#
# Copyright:: 2015-2021, IBM Corp.
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
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'bare-metal-stubs'

    it 'includes ironic common recipe' do
      expect(chef_run).to include_recipe('openstack-bare-metal::ironic-common')
    end

    it do
      expect(chef_run).to upgrade_package('ironic-api')
    end

    it do
      expect(chef_run).to disable_service('ironic-api').with(service_name: 'ironic-api')
      expect(chef_run).to stop_service('ironic-api').with(service_name: 'ironic-api')
    end

    it 'runs db migrations' do
      expect(chef_run).to run_execute('ironic db sync').with(user: 'root', group: 'root')
    end

    it do
      expect(chef_run).to install_apache2_install('openstack').with(listen: %w(127.0.0.1:6385))
    end

    it do
      expect(chef_run).to create_apache2_mod_wsgi 'bare-metal'
    end

    it do
      expect(chef_run).to_not enable_apache2_module('ssl')
    end

    it do
      expect(chef_run).to create_template('/etc/apache2/sites-available/ironic-api.conf').with(
        source: 'wsgi-template.conf.erb',
        variables: {
          daemon_process: 'ironic-wsgi',
          group: 'ironic',
          log_dir: '/var/log/apache2',
          run_dir: '/var/lock',
          server_entry: '/usr/bin/ironic-api-wsgi',
          server_host: '127.0.0.1',
          server_port: '6385',
          user: 'ironic',
        }
      )
    end
    [
      /<VirtualHost 127.0.0.1:6385>$/,
      /WSGIDaemonProcess ironic-wsgi processes=2 threads=10 user=ironic group=ironic display-name=%{GROUP}$/,
      /WSGIProcessGroup ironic-wsgi$/,
      %r{WSGIScriptAlias / /usr/bin/ironic-api-wsgi$},
      /WSGIApplicationGroup %{GLOBAL}$/,
      %r{ErrorLog /var/log/apache2/ironic-wsgi_error.log$},
      %r{CustomLog /var/log/apache2/ironic-wsgi_access.log combined$},
      %r{WSGISocketPrefix /var/lock$},
    ].each do |line|
      it do
        expect(chef_run).to render_file('/etc/apache2/sites-available/ironic-api.conf').with_content(line)
      end
    end

    [
      /SSLEngine On$/,
      /SSLCertificateFile/,
      /SSLCertificateKeyFile/,
      /SSLCACertificatePath/,
      /SSLCertificateChainFile/,
      /SSLProtocol/,
      /SSLCipherSuite/,
      /SSLVerifyClient require/,
    ].each do |line|
      it do
        expect(chef_run).to_not render_file('/etc/apache2/sites-available/ironic-api.conf').with_content(line)
      end
    end

    context 'Enable SSL' do
      cached(:chef_run) do
        node.override['openstack']['bare_metal']['ssl']['enabled'] = true
        node.override['openstack']['bare_metal']['ssl']['certfile'] = 'ssl.cert'
        node.override['openstack']['bare_metal']['ssl']['keyfile'] = 'ssl.key'
        node.override['openstack']['bare_metal']['ssl']['ca_certs_path'] = 'ca_certs_path'
        node.override['openstack']['bare_metal']['ssl']['protocol'] = 'ssl_protocol_value'
        runner.converge(described_recipe)
      end

      it do
        expect(chef_run).to enable_apache2_module('ssl')
      end

      [
        /SSLEngine On$/,
        /SSLCertificateFile ssl.cert$/,
        /SSLCertificateKeyFile ssl.key$/,
        /SSLCACertificatePath ca_certs_path$/,
        /SSLProtocol ssl_protocol_value$/,
      ].each do |line|
        it do
          expect(chef_run).to render_file('/etc/apache2/sites-available/ironic-api.conf').with_content(line)
        end
      end
      [
        /SSLCipherSuite/,
        /SSLCertificateChainFile/,
        /SSLVerifyClient require/,
      ].each do |line|
        it do
          expect(chef_run).to_not render_file('/etc/apache2/sites-available/ironic-api.conf').with_content(line)
        end
      end
      context 'Enable chainfile, ciphers & cert_required' do
        cached(:chef_run) do
          node.override['openstack']['bare_metal']['ssl']['enabled'] = true
          node.override['openstack']['bare_metal']['ssl']['ciphers'] = 'ssl_ciphers_value'
          node.override['openstack']['bare_metal']['ssl']['chainfile'] = 'chainfile'
          node.override['openstack']['bare_metal']['ssl']['cert_required'] = true
          runner.converge(described_recipe)
        end
        [
          /SSLCipherSuite ssl_ciphers_value$/,
          /SSLCertificateChainFile chainfile$/,
          /SSLVerifyClient require/,
        ].each do |line|
          it do
            expect(chef_run).to render_file('/etc/apache2/sites-available/ironic-api.conf').with_content(line)
          end
        end
      end
    end

    it do
      expect(chef_run.template('/etc/apache2/sites-available/ironic-api.conf')).to \
        notify('service[apache2]').to(:restart)
    end

    it do
      expect(chef_run).to enable_apache2_site('ironic-api')
    end

    it do
      expect(chef_run.apache2_site('ironic-api')).to notify('service[apache2]').to(:restart).immediately
    end
  end
end
