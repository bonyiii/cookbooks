include_recipe "gentoo::portage"

unless node[:gentoo][:use_flags].include?("syslog")
  node[:gentoo][:use_flags] << "syslog"
  generate_make_conf "added syslog USE flag"
end

package "app-admin/syslog-ng" do
  action :upgrade
end

cookbook_file "/etc/syslog-ng/syslog-ng.conf" do
  source "syslog-ng.conf"
  owner "root"
  group "root"
  mode "0600"
end

service "syslog-ng" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
  subscribes :reload, resources(:cookbook_file => "/etc/syslog-ng/syslog-ng.conf")
  subscribes :restart, resources(:package => "app-admin/syslog-ng")
end

if node.run_list.include?("logrotate")
  logrotate_config "syslog-ng"
end

if node.run_list.include?("monit")
  monit_check "syslog-ng"
end

if node.run_list.include?("nagios::nrpe")
  nrpe_command "syslog-ng"
end
