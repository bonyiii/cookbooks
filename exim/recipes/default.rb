case node[:platform]
  when "gentoo"
  include_recipe "gentoo::portage"
  
  gentoo_package "mail-mta/ssmtp" do
    action :remove
  end
  
  gentoo_package "mail-mta/exim" do
    action :upgrade
  end
end