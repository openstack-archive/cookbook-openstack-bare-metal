OpenStack Chef Cookbook - bare-metal
====================================

.. image:: https://governance.openstack.org/badges/cookbook-openstack-bare-metal.svg
    :target: https://governance.openstack.org/reference/tags/index.html

Description
===========

This cookbook installs the OpenStack Bare Metal service **Ironic** as
part of the OpenStack reference deployment Chef for OpenStack. The
`OpenStack chef-repo`_ contains documentation for using this cookbook in
the context of a full OpenStack deployment. Nova is currently installed
from packages.

.. _OpenStack chef-repo: https://opendev.org/openstack/openstack-chef

https://docs.openstack.org/ironic/latest/

Requirements
============

- Chef 16 or higher
- Chef Workstation 21.10.640 for testing (also includes Berkshelf for
  cookbook dependency resolution)

Platform
========

- ubuntu
- redhat
- centos

Cookbooks
=========

The following cookbooks are dependencies:

- 'apache2', '~> 8.6'
- 'openstack-common', '>= 20.0.0'
- 'openstack-identity', '>= 20.0.0'
- 'openstack-image', '>= 20.0.0'
- 'openstack-network', '>= 20.0.0'

Attributes
==========

Please see the extensive inline documentation in ``attributes/*.rb`` for
descriptions of all the settable attributes for this cookbook.

Note that all attributes are in the ``default['openstack']`` "namespace"

The usage of attributes to generate the ``ironic.conf`` is described in the
openstack-common cookbook.

Recipes
=======

openstack-bare-metal::api
-------------------------

- Installs the ``ironic-api``, sets up the ironic database

openstack-bare-metal::conductor
-------------------------------

- Installs the ``ironic-conductor`` service

openstack-bare-metal::default
-----------------------------

- Temp workaround to create ironic db with user

openstack-bare-metal::identity_registration
-------------------------------------------

- Registers ironic service/user/endpoints in keystone

openstack-bare-metal::ironic-common
-----------------------------------

- Defines the common pieces of repeated code from the other recipes

License and Author
==================

+-----------------+---------------------------------------------------+
| **Author**      | Mark Vanderwiel <vanderwl@us.ibm.com>             |
+-----------------+---------------------------------------------------+
| **Author**      | Ma Wen Cheng <wenchma@cn.ibm.com>                 |
+-----------------+---------------------------------------------------+
| **Author**      | Jan Klare <j.klare@cloudbau.de>                   |
+-----------------+---------------------------------------------------+
| **Author**      | Jens Harbott <j.harbott@x-ion.de>                 |
+-----------------+---------------------------------------------------+
| **Author**      | Lance Albertson <lance@osuosl.org>                |
+-----------------+---------------------------------------------------+
| **Author**      | Samuel Cassiba <samuel@cassi.ba>                  |
+-----------------+---------------------------------------------------+

+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2015, IBM, Corp.                    |
+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2019, x-ion GmbH                    |
+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2019-2021, Oregon State University  |
+-----------------+---------------------------------------------------+

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

::

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
