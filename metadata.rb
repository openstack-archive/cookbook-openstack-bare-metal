name 'openstack-bare-metal'
maintainer 'openstack-chef'
maintainer_email 'openstack-dev@lists.openstack.org'
license 'Apache-2.0'
description 'Installs/Configures OpenStack Bare Metal service Ironic'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '18.0.0'
issues_url 'https://launchpad.net/openstack-chef' if respond_to?(:issues_url)
source_url 'https://github.com/openstack/cookbook-openstack-bare-metal' if respond_to?(:source_url)
chef_version '>= 12.5' if respond_to?(:chef_version)

recipe 'openstack-bare-metal::api', 'Installs the ironic-api, sets up the ironic database'
recipe 'openstack-bare-metal::conductor', 'Installs the ironic-conductor service'
recipe 'openstack-bare-metal::default', 'Temp workaround to create ironic db with user'
recipe 'openstack-bare-metal::identity_registration', 'Registers ironic service/user/endpoints in keystone'
recipe 'openstack-bare-metal::ironic-common', 'Defines the common pieces of repeated code from the other recipes'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'openstack-common', '>= 18.0.0'
depends 'openstack-identity', '>= 18.0.0'
depends 'openstack-image', '>= 18.0.0'
depends 'openstack-network', '>= 18.0.0'
