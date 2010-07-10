include Opscode::PostgreSQL

action :create do
  unless postgresql_database_exists?(new_resource.name)
    postgresql_create_database(new_resource.name, new_resource.owner)
  else
    Chef::Log.debug("PostgreSQL database \"#{new_resource.name}\" exists.")
  end
  
  unless new_resource.owner.blank?
    postgresql_user "#{new_resource.owner}" do
      createdb new_resource.owner_createdb
      createrole new_resource.owner_createrole
      login new_resource.owner_login
      superuser new_resource.owner_superuser
      valid_until new_resource.owner_valid_until
      database new_resource.name
    end
  end
end

action :delete do
  if postgresql_database_exists?(new_resource.name)
    postgresql_drop_database(new_resource.name)
  else
    Chef::Log.debug("PostgresSQL database \"#{new_resource.name}\" doesn't exist.")
  end
end
