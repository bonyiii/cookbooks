include_recipe "mysql::client"
include_recipe "gentoo::portage"

gentoo_package_use "dev-db/mysql latin1" do
  action node[:mysql][:encoding] == "latin1" ? :create : :delete
end

package "dev-db/mysql" do
  action :upgrade
end

# TODO mysql master/slave configuration
template "/etc/mysql/my.cnf" do
  source "my.cnf.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :encoding => node[:mysql][:encoding],
    :server_mode => node[:mysql][:server][:mode],
    :server_id => node[:mysql][:server][:id],
    :bind_address => node[:mysql][:server][:bind_address],
    :max_connections => node[:mysql][:server][:max_connections],
    :mysqld_variables => node[:mysql][:server][:mysqld_variables]
  )
end

execute "emerge --config dev-db/mysql" do
  user "root"
  group "root"
  creates "/var/lib/mysql/mysql"
end

service "mysql" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  subscribes :restart, resources(:package => "dev-db/mysql", :template => "/etc/mysql/my.cnf")
end

mysql_database "test" do
  action :delete
end

mysql_database "processcope" do
  action :create
end

mysql_user "processcope" do
  action :create
  password "kope"
end

mysql_user "valaki" do
  action :create
  password "kope"
end

mysql_grant "Giving all privileges to valaki" do
  action :delete
  grant_option false
  privileges "ALL"
  user "valaki"
  database "processcope"
end


=begin
if node.recipe?("iptables")
  ips = [node[:mysql][:client_ips]].flatten.select { |i| i != "127.0.0.1" }
  iptables_rule "mysql" do
    variables(:ips => ips)
    action !ips.empty? ? :create : :delete
  end
end

if node.recipe?("monit")
  monit_check "mysql" do
    variables(:bind_address => node[:mysql][:server][:bind_address])
  end
end

if node.recipe?("nagios::nrpe")
  nrpe_password = get_password("mysql/nrpe")
  mysql_user "nrpe" do
    password nrpe_password
  end
  mysql_grant "nrpe_process" do
    user "nrpe"
    database "*"
    privileges "PROCESS"
  end

  nrpe_command "mysql" do
    variables(:password => nrpe_password)
  end
end
=end