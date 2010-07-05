#/postgresql.conf.
# Cookbook Name:: postgresql
# Recipe:: server
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

include_recipe "postgresql::client" 

case node[:platform]
  when "gentoo"
  include_recipe "gentoo::portage"
  
  gentoo_package "dev-ruby/ruby-postgres"
  
  # To be able manipulate postgresql server via ruby.
  gentoo_package "dev-db/postgresql-server"
  
  # Set default encoding in /etc/conf.d for emerge --config
  template "/etc/conf.d/postgresql-#{node[:postgresql][:version][node[:platform]][:default]}" do
    source "conf.d-postgresql-#{node[:postgresql][:version][node[:platform]][:default]}.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
    :locale => node[:postgresql][:locale],
    :encoding => node[:postgresql][:encoding],
    :listen_address => node[:postgresql][:listen_address])
  end
  
  # Set sensible defaults and run initdb via emerge --config  
  script "Conifgure Postgresql server" do
    interpreter "bash"
    user "root"
    creates "#{node[:postgresql][:dir]}/postgresql.conf"
    code <<-EOF
    echo "y\n" > /tmp/answer_yes
    emerge --config dev-db/postgresql-server < /tmp/answer_yes 
    rm /tmp/answer_yes
    EOF
  end
else
  package "postgresql"
end

service "postgresql" do
  case node[:platform]
    when "debian","ubuntu", "gentoo"
    service_name "postgresql-#{node[:postgresql][:version][node[:platform]][:default]}"
    #service_name "postgresql-#{node[:postgresql][:version]}"
  end
  supports :restart => true, :status => true, :reload => true
  #action :nothing
  action [:enable, :start]
end

template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  notifies :restart, resources(:service => "postgresql")
  variables(:encoding => node[:postgresql][:encoding])
end

# To erase a database set action something else than :enable
postgresql_database "teszt" do
  action :enable2
  owner "postgres"
  encoding node[:postgresql][:encoding]
end

=begin


template "#{node[:postgresql][:dir]}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  notifies :reload, resources(:service => "postgresql")
end

=end