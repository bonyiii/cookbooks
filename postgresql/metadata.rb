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

attribute "postgresql/encoding",
  :display_name => "Postgresql encoding",
  :description => "Encoding used by PostgreSQL server",
  :type => "string",
  :default => "en_US.UTF-8"
