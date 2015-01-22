# Encoding: utf-8
#
# Cookbook Name:: openstack-bare-metal
# Recipe:: default
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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

# TODO(wenchma) A temporary workaround to ironic database with user instead of openstack-ops-database.
# These could be removed and replaced by the following patch once Kilo branch is created.
# https://review.openstack.org/#/c/148463/
db_create_with_user(
  'bare-metal',
  node['openstack']['db']['bare-metal']['username'],
  get_password('db', 'ironic')
)
