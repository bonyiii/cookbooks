include Opscode::PostgreSQL

action :create do
  postgresql_manage_grants(:create, new_resource)
end

action :delete do
  postgresql_manage_grants(:delete, new_resource)
end
