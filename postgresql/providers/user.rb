include Opscode::PostgreSQL
include Opscode::Password

action :create do
  password = new_resource.password
  if password.to_s == ""
    password = get_password("postgresql/#{new_resource.name}")
  end
  
  if postgresql_user_exists?(new_resource.name)
    if new_resource.force_password
      postgresql_force_password(new_resource, password)
    end
    Chef::Log.debug("PostgreSQL user \"#{new_resource.name}\" exists.")
  else
    postgresql_create_user(new_resource, password)
  end
end

action :delete do
  begin
    postgresql_drop_user(new_resource) if postgresql_user_exists?(new_resource.name)
  rescue
    Chef::Log.warn("Cannot delete PostgreSQL user: #{$!}")
  end
end
