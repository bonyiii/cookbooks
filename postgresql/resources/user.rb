# http://www.postgresql.org/docs/8.4/interactive/sql-createuser.html
def initialize(name, run_context=nil)
  super(name, run_context)
  @action = :create
end

actions :create, :delete

attribute :password,       :kind_of => String
attribute :force_password, :kind_of => [TrueClass, FalseClass], :default => false
attribute :createdb,       :kind_of => [TrueClass, FalseClass], :default => false
attribute :createrole,     :kind_of => [TrueClass, FalseClass], :default => false
attribute :login,          :kind_of => [TrueClass, FalseClass], :default => true
attribute :superuser,      :kind_of => [TrueClass, FalseClass], :default => false
attribute :valid_until,    :kind_of => String
# If we create a user and that user should owns a database 
attribute :database,       :kind_of => String