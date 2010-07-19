case node[:platform]
  when "gentoo"
  include_recipe "gentoo::portage"
  
  gentoo_package "mail-mta/ssmtp" do
    action :remove
  end
  
  gentoo_package_use "net-nds/openldap sasl" do
    action :create
  end
  
  gentoo_package "mail-mta/exim" do
    action :upgrade
    use ["maildir", "syslog", "ldap", "ipv6", "tcpd", "-gnutls"]
  end
end


service "exim" do
  case node[:platform]
    when "debian","ubuntu", "gentoo"
    service_name "postgresql-#{node[:postgresql][:version][node[:platform]][:default]}"
    #service_name "postgresql-#{node[:postgresql][:version]}"
  end
  supports :restart => true, :status => true, :reload => true
  #action :nothing
  action [:enable, :start]
end