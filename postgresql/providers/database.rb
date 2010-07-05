include Opscode::PostgreSQL

action :create do
  unless postgresql_database_exists?(new_resource.name)
    postgresql_create_database(new_resource.name)
  else
    Chef::Log.debug("PostgreSQL database \"#{new_resource.name}\" exists.")
  end
  unless new_resource.owner.to_s == ""
    postgresql_user "#{new_resource.owner}" do
      host new_resource.owner_host
    end
    postgresql_grant "#{new_resource.name}_#{new_resource.owner}" do
      database new_resource.name
      user new_resource.owner
      user_host new_resource.owner_host
      privileges "ALL"
    end
  end
end

action :delete do
  if postgresql_database_exists?(new_resource.name)
    postgresql_drop_database(new_resource.name)
  else
    Chef::Log.debug("PostgresSQL database \"#{new_resource.name}\" doesn't exist.")
  end
  unless new_resource.owner.to_s == ""
    postgresql_grant "#{new_resource.name}_#{new_resource.owner}" do
      action :delete
      database new_resource.name
      user new_resource.owner
      user_host new_resource.owner_host
    end
  end
end
