maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs and configures postgresql for clients or servers"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version           "0.9"
recipe            "postgresql::client", "Installs postgresql client package(s)"
recipe            "postgresql::server", "Installs postgresql server packages, templates"

%w{rhel centos fedora ubuntu debian gentoo}.each do |os|
  supports os
end

attribute "postgresql/version",
  :display_name => "PostgreSQL server version",
  :description => "PostgreSQL server version. Depends on node platform",
  :type => "hash",
  :default => "8.4"
  
attribute "postgresql/dir",
  :display_name => "PostgreSQL server config files directory",
  :description => "Directory that contains PostgreSQL server config files like pga_hba.conf. Depends on node platform",
  :type => "hash",
  :default => "/var/lib/pgsql/data/8.4"

attribute "postgresql/locale",
  :display_name => "PostgreSQL locale settings",
  :description => "Locales used by PostgreSQL server",
  :type => "string",
  :default => "en_US"

attribute "postgresql/encoding",
  :display_name => "Postgresql encoding",
  :description => "Encoding used by PostgreSQL server",
  :type => "string",
  :default => "en_US.UTF-8"

attribute "postgresql/listen_addresses",
  :display_name => "PostgreSQL server listen address",
  :description => "IP address(es) to listen on, comma-separated list of addresses, defaults to 'localhost', '*' = all",
  :type => "string",
  :default => "*"