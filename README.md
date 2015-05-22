cookbook-openstack-bare-metal Cookbook
======================================

This cookbook installs the OpenStack Bare Metal service **Ironic** as part of
the OpenStack reference deployment Chef for OpenStack. Ironic is currently
installed from packages.

https://wiki.openstack.org/wiki/Ironic

Requirements
------------

Chef 12 or higher required (for Chef environment use).

Attributes
----------

Please see the extensive inline documentation in `attributes/*.rb` for descriptions
of all the settable attributes for this cookbook.

There are also many common attributes shared across the cookbooks that are found in
the cookbook-openstack-common cookbook attribute files.

Note that all attributes are in the `default["openstack"]` "namespace"


Usage
-----
#### cookbook-openstack-bare-metal::default
TODO: Write usage instructions for each cookbook.


Contributing
------------

Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) for instructions for contributing.

Testing
-------

Please refer to the [TESTING.md](TESTING.md) for instructions for testing the cookbook.

License and Authors
-------------------

|                      |                                                    |
|:---------------------|:---------------------------------------------------|
| **Author**           |   Wen Cheng Ma(<wenchma@cn.ibm.com>)               |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2014-2015, IBM, Corp.               |


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
