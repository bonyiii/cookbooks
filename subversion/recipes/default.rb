gentoo_package "dev-vcs/subversion" do
  action :upgrade
  use [ "webdav-neon" ,"dso", "doc"]
end
