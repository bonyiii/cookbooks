module Opscode
  module PostgreSQL
    
    @@dbh = nil
    @@users = nil
    @@grants = nil
    @@databases = nil
    
    def postgresql_database_exists?(database)
      postgresql_databases.include?(database)
    end
    
    private
    
    def postgresql_dbh
      return @@dbh if @@dbh
      require "pg"
      host = "localhost"
      port = 5432
      db = "postgres"
      user = "postgres"
      password = "password"
      #password = nil
      oksection = false
      File.read("/root/.pgpass").split(":").each { |option|
        if option.strip =~ /\A\[(\S+)\]\Z/
          oksection = %w(mysql client).include?($1)
        elsif oksection && option.strip =~ /\Ahost\s*=\s*(\S+)\Z/
          host = $1
        elsif oksection && option.strip =~ /\Apassword\s*=\s*(\S+)\Z/
          password = $1
        end
      }
      
      # Connect to the PostgreSQL server. Options are:
      #pghost : Server hostname(string) 
      #pgport : Server port number(integer) 
      #pgoptions : backend options(string) 
      #pgtty : tty to print backend debug message(string) 
      #dbname : connecting database name(string) 
      #login : login user name(string) 
      #passwd : login password(string)
      @@dbh = ::PGconn.connect(host, port, "", "", db, user, password)
    end
    
    def postgresql_databases
      return @@databases if @@databases
       postgresql_dbh.exec("select datname from pg_database").each do |database|
        @@databases << database
      end
    end
    
  end # module PostgreSQL
end
