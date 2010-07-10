#
# Cookbook Name:: postgresql
# Attributes:: postgresql
#
# Copyright 2008-2009, Opscode, Inc.
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

set[:postgresql][:version] = value_for_platform(
  "ubuntu" => {
    "8.04" => "8.3",
    "8.10" => "8.3",
    "9.10" => "8.3",
    "10.04" => "8.4",
    "default" => "8.4"
  },
  "fedora" => {
    "10" => "8.3",
    "11" => "8.3",
    "12" => "8.3",
    "13" => "8.4",
    "14" => "8.4",
    "default" => "8.4"
  },
  ["redhat", "centos"] => {
    "default" => "8.3"
  },
  "gentoo" => {
    "default" => "8.4"
  }
)

case platform
when "redhat","centos","fedora","suse"
  set[:postgresql][:dir]     = "/var/lib/pgsql/data"
when "debian","ubuntu"
  set[:postgresql][:dir]     = "/etc/postgresql/#{node.postgresql.version}/main"
when "gentoo"
  #Chef::Log.info("attributes/default #{node[:postgresql][:version][node[:platform]][:default]}")
  #set[:postgresql][:dir]     = "/var/lib/postgresql/#{node[:postgresql][:version]}/data"
  set[:postgresql][:dir]     = "/var/lib/postgresql/#{node[:postgresql][:version][node[:platform]][:default]}/data"
else
  set[:postgresql][:dir]     = "/etc/postgresql/#{node.postgresql.version}/main"
end

default[:postgresql][:locale] = "en_US"
default[:postgresql][:encoding] = "UTF-8"
default[:postgresql][:listen_addresses] = "*"

default[:postgresql][:acls] = [
{
  :type => "host",
  :database => "postgres",
  :user => "postgres",
  :cidr_address => "192.168.0.0/16",
  :method => "md5"
}
]

# For .dot.pgpass
default[:postgresql][:server_address] = "localhost"
default[:postgresql][:port] = 5432
default[:postgresql][:database] = "postgres"
default[:postgresql][:root] = "postgres"
default[:postgresql][:root_password] = "password"
