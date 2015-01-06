name             'openstack-bare-metal'
maintainer       'openstack-chef'
maintainer_email 'opscode-chef-openstack@googlegroups.com'
license          'Apache 2.0'
description      'Installs/Configures OpenStack Bare Metal service Ironic'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '11.0.0'

depends          'openstack-common', '~> 10.0'
