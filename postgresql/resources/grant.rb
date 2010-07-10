# http://dev.mysql.com/doc/refman/5.0/en/grant.html
def initialize(name, run_context=nil)
  super(name, run_context)
  @action = :create
end

actions :create, :delete

attribute :privileges,   :kind_of => [String, Array], :default => "ALL"
attribute :on,           :kind_of => String, :required => true
attribute :user,         :kind_of => String, :required => true
attribute :grant_option, :kind_of => [TrueClass, FalseClass], :default => false
attribute :conn_db,      :kind_of => String, :required => true

# TODO attribute :function,     :kind_of => String
# TODO attribute :procedure,    :kind_of => String
