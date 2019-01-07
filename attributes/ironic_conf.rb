default['openstack']['bare_metal']['conf_secrets'] = {}

default['openstack']['bare_metal']['conf'].tap do |conf|
  if node['openstack']['bare_metal']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  end
  conf['DEFAULT']['auth_strategy'] = 'keystone'
  conf['DEFAULT']['control_exchange'] = 'ironic'
  conf['DEFAULT']['glance_api_version'] = '2'
  conf['DEFAULT']['state_path'] = '/var/lib/ironic'

  conf['keystone_authtoken']['auth_type'] = 'password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'ironic'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'

  conf['oslo_concurrency']['lock_path'] = '/var/lib/cinder/tmp'
end
