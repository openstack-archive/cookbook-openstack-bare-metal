name 'openstack-bare-metal'
maintainer 'openstack-chef'
maintainer_email 'openstack-discuss@lists.openstack.org'
license 'Apache-2.0'
description 'Installs/Configures OpenStack Bare Metal service Ironic'
version '18.0.0'
issues_url 'https://launchpad.net/openstack-chef'
source_url 'https://opendev.org/openstack/cookbook-openstack-bare-metal'
chef_version '>= 14.0'

recipe 'openstack-bare-metal::api', 'Installs the ironic-api, sets up the ironic database'
recipe 'openstack-bare-metal::conductor', 'Installs the ironic-conductor service'
recipe 'openstack-bare-metal::default', 'Temp workaround to create ironic db with user'
recipe 'openstack-bare-metal::identity_registration', 'Registers ironic service/user/endpoints in keystone'
recipe 'openstack-bare-metal::ironic-common', 'Defines the common pieces of repeated code from the other recipes'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'apache2', '~> 8.0'
depends 'openstack-common', '>= 18.0.0'
depends 'openstack-identity', '>= 18.0.0'
depends 'openstack-image', '>= 18.0.0'
depends 'openstack-network', '>= 18.0.0'
