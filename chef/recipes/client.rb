include_recipe "gentoo::portage"
# Ez már nem kell
#include_recipe "chef::overlay"

package "app-admin/chef" do
  action :upgrade
end

if node.run_list?("chef::server")
  node[:chef][:client][:server_url] = "http://192.168.45.2:4000"
else
  file "/etc/chef/validation.pem" do
    action :delete
    backup false
    only_if { File.size?("/etc/chef/client.pem") }
  end
end

if %w(yes true on 1).include?(node[:chef][:syslog].to_s)
  gentoo_package "dev-ruby/SyslogLogger" do
    action :upgrade
    keywords "=dev-ruby/SyslogLogger-1.4.0"
  end
elsif node.run_list?("logrotate")
  # TODO eliminate copytuncate http://tickets.opscode.com/browse/CHEF-1116
  logrotate_config "chef"
end

ruby_block "reload_client_config" do
  block do
    Chef::Config.from_file("/etc/chef/client.rb")
  end
  action :nothing
end

template "/etc/chef/client.rb" do
  source "client.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :chef_server_url => node[:chef][:client][:server_url],
    :syslog => node[:chef][:syslog]
  )
  notifies :create, resources(:ruby_block => "reload_client_config")
end

service "chef-client" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  subscribes :restart, resources(:package => "app-admin/chef")
end

directory "/var/lib/chef/cache" do
  owner "root"
  group "root"
  group node.run_list?("chef::server") ? "chef" : "root"
  mode "0770"
end

file "/var/log/chef/client.log" do
  owner "root"
  group "root"
  mode "0600"
  only_if { File.size?("/var/log/chef/client.log") }
end

if node.run_list?("monit")
  monit_check "chef-client" do
    variables(:to => node[:monit][:alert_mail_to])
 end
end

if node.run_list?("nagios::nrpe")
  nrpe_command "chef-client"
end
