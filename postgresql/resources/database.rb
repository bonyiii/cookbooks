# http://dev.mysql.com/doc/refman/5.0/en/create-database.html
def initialize(name, run_context=nil)
  super(name, run_context)
  @action = :create
end

actions :create, :delete

attribute :owner,                :kind_of => String
attribute :encoding,             :kind_of => String
attribute :owner_createdb,       :kind_of => [TrueClass, FalseClass], :default => false
attribute :owner_createrole,     :kind_of => [TrueClass, FalseClass], :default => false
attribute :owner_login,          :kind_of => [TrueClass, FalseClass], :default => true
attribute :owner_superuser,      :kind_of => [TrueClass, FalseClass], :default => false
attribute :owner_valid_until,    :kind_of => String
