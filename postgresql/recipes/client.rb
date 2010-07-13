#
# Cookbook Name:: postgresql
# Recipe:: client
#
# Copyright 2009, Opscode, Inc.
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
include_recipe "password"

case node[:platform] 
  when "ubuntu","debian"
  package "postgresql-client"
  when "redhat","centos","fedora"
  package "postgresql-devel"
  when "gentoo"
  include_recipe "gentoo::portage"
  gentoo_package "dev-db/postgresql-base"
end

# set node[:postgresql][:root_password] to "" and we'll generate and store the
# PostgreSQL root password locally
postgresql_user_password = if node[:postgresql][:pgpass][:user_password] == ""
  get_password("postgresql/root")
else
  node[:postgresql][:pgpass][:user_password]
end

template "/root/.pgpass" do
  source "dot.pgpass.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :host => node[:postgresql][:pgpass][:server_address],
    :port => node[:postgresql][:pgpass][:port],
    :database => node[:postgresql][:pgpass][:database],
    :username => node[:postgresql][:pgpass][:user],
    :password => postgresql_user_password
  )
end