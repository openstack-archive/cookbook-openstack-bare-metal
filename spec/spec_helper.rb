require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.log_level = :warn
end

REDHAT_7 = {
  platform: 'redhat',
  version: '7',
}.freeze

REDHAT_8 = {
  platform: 'redhat',
  version: '8',
}.freeze

ALL_RHEL = [
  REDHAT_7,
  REDHAT_8,
].freeze

UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '18.04',
}.freeze

shared_context 'bare-metal-stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return('1.1.1.1:5672,2.2.2.2:5672')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('admin_test_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-bare-metal')
      .and_return('ironic_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('bare_metal')
      .and_return('rabbit://guest:mypass@127.0.0.1:5672')
    stub_command('/usr/sbin/httpd -t').and_return(true)
    stub_command('/usr/sbin/apache2 -t').and_return(true)
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers).and_return []
    allow(Chef::Application).to receive(:fatal!)
    # identity stubs
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'credential_key0')
      .and_return('thisiscredentialkey0')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'credential_key1')
      .and_return('thisiscredentialkey1')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'fernet_key0')
      .and_return('thisisfernetkey0')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'fernet_key1')
      .and_return('thisisfernetkey1')
    allow_any_instance_of(Chef::Recipe).to receive(:search_for)
      .with('os-identity').and_return(
        [{
          'openstack' => {
            'identity' => {
              'admin_tenant_name' => 'admin',
              'admin_user' => 'admin',
            },
          },
        }]
      )
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers)
      .and_return([])
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('identity')
      .and_return('rabbit://openstack:mypass@127.0.0.1:5672')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'keystone')
      .and_return('test-passes')
  end
end

shared_examples 'expect runs openstack common logging recipe' do
  it 'runs logging recipe if node attributes say to' do
    expect(chef_run).to include_recipe 'openstack-common::logging'
  end
end

shared_examples 'expect installs common ironic package' do
  it 'installs the openstack-ironic common package' do
    expect(chef_run).to upgrade_package 'openstack-ironic-common'
  end
end

shared_examples 'expect installs mysql package' do
  it 'installs mysql python packages by default' do
    expect(chef_run).to upgrade_package 'MySQL-python'
  end
end

shared_examples 'expect runs db migrations' do
  it 'runs db migrations' do
    expect(chef_run).to run_execute('ironic-dbsync').with(user: 'ironic', group: 'ironic')
  end
end

shared_examples 'expects to create ironic directories' do
  it 'creates /etc/ironic' do
    expect(chef_run).to create_directory('/etc/ironic').with(
      owner: 'ironic',
      group: 'ironic',
      mode: '750'
    )
  end
end

shared_examples 'expects to create ironic conf' do
  describe 'ironic.conf' do
    let(:file) { chef_run.template('/etc/ironic/ironic.conf') }

    it 'creates the ironic.conf file' do
      expect(chef_run).to create_template(file.name).with(
        owner: 'ironic',
        group: 'ironic',
        mode: '640'
      )
    end

    it 'sets auth_encryption_key' do
      expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^auth_encryption_key = auth_encryption_key_secret$/)
    end

    describe 'default values'
    it 'has default conf values' do
      [
        %r{^log_dir = /var/log/ironic$},
        /^region_name_for_services = RegionOne$/,
      ].each do |line|
        expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
      end
    end

    it 'sets database connection value' do
      expect(chef_run).to render_config_file(file.name).with_section_content(
        'database', %r{^connection = mysql\+pymysql://ironic:ironic@127.0.0.1:3306/ironic\?charset=utf8$}
      )
    end
  end

  describe 'has oslo_messaging_rabbit values' do
    it 'has default rabbit values' do
      [
        %r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$},
      ].each do |line|
        expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
      end
    end
  end

  describe 'has keystone_authtoken values' do
    it 'has default keystone_authtoken values' do
      [
        %r{^auth_url = http://127.0.0.1:5000/v3$},
        /^auth_type = password$/,
        /^username = ironic$/,
        /^project_name = service$/,
        /^user_domain_name = Default/,
        /^project_domain_name = Default/,
        /^password = ironic_pass$/,
      ].each do |line|
        expect(chef_run).to render_config_file(file.name).with_section_content('keystone_authtoken', line)
      end
    end
  end
end

shared_examples 'logging' do
  context 'with logging enabled' do
    before do
      node.override['openstack']['bare_metal']['syslog']['use'] = true
    end

    it 'runs logging recipe if node attributes say to' do
      expect(chef_run).to include_recipe 'openstack-common::logging'
    end
  end

  context 'with logging disabled' do
    before do
      node.override['openstack']['bare_metal']['syslog']['use'] = false
    end

    it 'does not run logging recipe' do
      expect(chef_run).not_to include_recipe 'openstack-common::logging'
    end
  end
end
