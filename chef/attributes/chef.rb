default[:chef][:syslog] = false
#default[:chef][:client][:server_url] = "http://chef.#{node[:domain]}:4000"
default[:chef][:client][:server_url] = "http://192.168.45.2:4000"
default[:chef][:server][:amqp_pass] = "password"
default[:chef][:server][:server_proxy_port] = "4443"
default[:chef][:server][:webui_proxy_port] = "4483"
