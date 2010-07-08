module Opscode
  module PostgreSQL
    
    @@dbh = nil
    @@users = nil
    @@grants = nil
    @@databases = nil
    
    def postgresql_user_exists?(user)
      postgresql_users.include?("#{user.name}")
    end
    
    def postgresql_database_exists?(database)
      postgresql_databases.include?(database)
    end
    
    def postgresql_create_database(database)
      @@databases = nil
      Chef::Log.info("Creating PostgreSQL database \"#{database}\".")
      Chef::Log.debug("PostgreSQL query: CREATE DATABASE #{postgresql_dbh.quote_ident(database)}")
      postgresql_dbh.query("CREATE DATABASE #{postgresql_dbh.quote_ident(database)}")
    end
    
    def postgresql_drop_database(database)
      @@databases = nil
      Chef::Log.info("Dropping PostgreSQL database \"#{database}\".")
      drop_query ="DROP DATABASE #{postgresql_dbh.quote_ident(database)}"
      Chef::Log.debug("PostgreSQL query: #{drop_query}")
      postgresql_dbh.query(drop_query)
    end
    
    def postgresql_create_user(user, password)
      @@users = nil
      Chef::Log.info("Creating PostgreSQL user \"#{user.name}\".")
      create_query = "CREATE USER #{postgresql_dbh.quote_ident(user.name)} WITH PASSWORD '#{postgresql_dbh.quote_ident(password)}'"
      create_query += " CREATEDB" if user.createdb
      create_query += " CREATEROLE" if user.createrole
      create_query += " NOLOGIN" unless user.login
      create_query += " SUPERUSER" if user.superuser
      create_query += " #{postgresql_dbh.quote_ident(user.valid_until)}" if user.valid_until
      
      Chef::Log.debug("PostgreSQL query: #{create_query}")
      postgresql_dbh.query(create_query)
      #postgresql_dbh.reload
    end
    
    def  postgresql_drop_user(user)
      @@users = nil
      Chef::Log.info("Dropping PostgreSQL user \"#{user.name}\".")
      query="DROP USER #{postgresql_dbh.quote_ident(user.name)}"
      Chef::Log.debug("PostgreSQL #{query}")
      postgresql_dbh.query(query)
    end
    
    
    # TODO: finish
    def postgresql_force_password(user, password)
      password_ok = false
      select_query =
      "SELECT password FROM pg_shadow WHERE usename ILIKE #{postgresql_dbh.quote_ident(user)} " + 
      "AND passwd=MD5(#{postgresql_dbh.quote_ident(password) + postgresql_dbh.quote_ident(user)})"
      Chef::Log.debug("PostgreSQL query: #{select_query}")
      postgresql_dbh.query(select_query).each { |row| password_ok = row[0] == row[1] }
      unless password_ok
        Chef::Log.info("Reseting MySQL password of #{user.name}@#{user.host}.")
        set_query = "SET PASSWORD FOR #{mysql_user_handle(user)} " +
          "= PASSWORD('#{mysql_dbh.quote(password)}')"
        Chef::Log.debug("MySQL query: #{set_query}")
        mysql_dbh.query(set_query)
        mysql_dbh.reload
      else
        Chef::Log.debug("MySQL password OK for #{user.name}@#{user.host}.")
      end
    end
    
    def postgresql_manage_grants(action, grant)
      privileges = postgresq_user_privileges(grant)
      current_db_privileges = privileges[grant.database] || []
      new_db_privileges = [grant.privileges].flatten.map { |p| p.upcase }
      case action
        when :create
        unless current_db_privileges.include?("ALL")
          missing_privileges = new_db_privileges - current_db_privileges
          unless missing_privileges.empty?
            mysql_manage_privileges(:create, grant, missing_privileges)
          else
            Chef::Log.debug("MySQL user #{grant.user}@#{grant.user_host} has all necessary privileges on database \"#{grant.database}\".")
          end
        else
          Chef::Log.debug("MySQL user #{grant.user}@#{grant.user_host} has ALL privileges on database \"#{grant.database}\".")
        end
        when :delete
        if new_db_privileges.include?("ALL") && !current_db_privileges.empty?
          mysql_manage_privileges(:delete, grant, "ALL")
        else
          unwanted_privileges = current_db_privileges & new_db_privileges
          unless unwanted_privileges.empty?
            mysql_manage_privileges(:delete, grant, unwanted_privileges)
          else
            Chef::Log.debug("MySQL user #{grant.user}@#{grant.user_host} has no unwanted privileges on database \"#{grant.database}\".")
          end
        end
      end
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
=begin
      File.read("/root/.pgpass").split(":").each { |option|
        if option.strip =~ /\A\[(\S+)\]\Z/
          oksection = %w(mysql client).include?($1)
        elsif oksection && option.strip =~ /\Ahost\s*=\s*(\S+)\Z/
          host = $1
        elsif oksection && option.strip =~ /\Apassword\s*=\s*(\S+)\Z/
          password = $1
        end
      }
=end
      
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
      @@databases = []
      select_query = "SELECT datname FROM pg_database"
      Chef::Log.debug("PostgreSQL query: #{select_query}")
      postgresql_dbh.exec(select_query).each do |database|
        @@databases << database["datname"]
      end
      @@databases
    end
    
    def postgresql_users
      return @@users if @@users
      @@users = []
      select_query = "SELECT usename FROM pg_shadow"
      Chef::Log.debug("PostgreSQL query: #{select_query}")
      postgresql_dbh.exec(select_query).each do |row|
        @@users << row["usename"]
      end
      @@users
    end
    
    
    # TODO: create_user doesn't use it
    def postgresql_user_handle(user, resource_type = :user)
      if resource_type == :grant
        # user is a grant :)
        "`#{postgresql_dbh.quote_ident(user.user)}`@`#{postgresql_dbh.quote_ident(user.user_host)}`"
      else
        "`#{postgresql_dbh.quote_ident(user.name)}`@`#{postgresql_dbh.quote_ident(user.host)}`"
      end
    end
    
  end # module PostgreSQL
end
