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
  
  gentoo_package "dev-ruby/pg" do
    action :upgrade
    keywords "dev-ruby/pg"
  end
  
  # To be able manipulate postgresql server via ruby.
  gentoo_package "dev-db/postgresql-server" do
    action :upgrade
  end
  
  # Set default encoding in /etc/conf.d for emerge --config
  template "/etc/conf.d/postgresql-#{node[:postgresql][:version][node[:platform]][:default]}" do
    source "conf.d-postgresql-#{node[:postgresql][:version][node[:platform]][:default]}.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
    :locale => node[:postgresql][:locale],
    :encoding => node[:postgresql][:encoding]
    )
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

#Logging
directory node[:postgresql][:log][:dir] do
  owner "postgres"
  group "postgres"
  mode 0755
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

# Postgres main config file, replaces the one that initdb creates :(
template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  notifies :restart, resources(:service => "postgresql")
  variables(
    :locale => node[:postgresql][:locale],
    :encoding => node[:postgresql][:encoding],
    :listen_addresses => node[:postgresql][:listen_addresses],
    :log_dir => node[:postgresql][:log][:dir]
  )
end

# ACL -s 
template "#{node[:postgresql][:dir]}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 0600
  notifies :restart, resources(:service => "postgresql")
  variables (:acls => node[:postgresql][:acls])
end

if node.postgresql.db.attribute?("name")
  postgresql_database node[:postgresql][:db][:name] do
    action :create
    owner node[:postgresql][:db][:user]
    owner_createdb true
    owner_createrole true
    encoding node[:postgresql][:encoding]
  end
  
  postgresql_user node[:postgresql][:db][:user] do
    password node[:postgresql][:db][:passwd]
    force_password true
  end
end
=begin
postgresql_database "teszt" do
  action :delete
end

postgresql_user "feri" do
  action :delete
end

postgresql_database "teszt" do
  action :create
  owner "feri"
  owner_createdb true
  owner_createrole true
  encoding node[:postgresql][:encoding]
end

execute "load_data_to_db_teszt" do
  command "/usr/bin/psql -U postgres teszt < /root/profi_gizike.sql"
end

postgresql_user "gizi" do
  action :delete
end

postgresql_user "gizi" do
  action :create
  password "ferike"
end

postgresql_user "gizi" do
  password "titok"
  force_password true
end

postgresql_grant "all_on_teszt_to_gizi" do
  on "users"
  user "gizi"
  privileges "ALL"
  conn_db "teszt"
end

postgresql_grant "revoke_all_on_teszt_to_gizi" do
  action :delete
  on "users"
  user "gizi"
  privileges "ALL"
  conn_db "teszt"
end

postgresql_database "match" do
  action :create
  owner "match"
  owner_createdb true
  owner_createrole true
  encoding node[:postgresql][:encoding]
end
=end