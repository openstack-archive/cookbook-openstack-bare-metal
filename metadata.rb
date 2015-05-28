name 'openstack-bare-metal'
maintainer 'openstack-chef'
maintainer_email 'opscode-chef-openstack@googlegroups.com'
license 'Apache 2.0'
description 'Installs/Configures OpenStack Bare Metal service Ironic'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '11.0.0'

recipe 'openstack-bare-metal::api', 'Installs the ironic-api, sets up the ironic database'
recipe 'openstack-bare-metal::conductor', 'Installs the ironic-conductor service'
recipe 'openstack-bare-metal::default', 'Temp workaround to create ironic db with user'
recipe 'openstack-bare-metal::identity_registration', 'Registers ironic service/user/endpoints in keystone'
recipe 'openstack-bare-metal::ironic-common', 'Defines the common pieces of repeated code from the other recipes'

depends 'openstack-common', '>= 11.0.0'
depends 'openstack-identity', '>= 11.0.0'
