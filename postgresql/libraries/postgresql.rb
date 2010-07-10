module Opscode
  module PostgreSQL
    
    @@dbh = nil
    @@users = nil
    @@grants = nil
    @@databases = nil
    
    def postgresql_user_exists?(user)
      postgresql_users.include?(user)
    end
    
    def postgresql_database_exists?(database)
      postgresql_databases.include?(database)
    end
    
    def postgresql_create_database(database, owner = nil )
      @@databases = nil
      Chef::Log.info("Creating PostgreSQL database \"#{database}\".")
      create_query = "CREATE DATABASE #{postgresql_dbh.escape(database)}"
      postgresql_dbh.query(create_query)
    end
    
    def postgresql_drop_database(database)
      @@databases = nil
      Chef::Log.info("Dropping PostgreSQL database \"#{database}\".")
      drop_query ="DROP DATABASE #{postgresql_dbh.escape(database)}"
      Chef::Log.debug("PostgreSQL query: #{drop_query}")
      postgresql_dbh.query(drop_query)
    end
    
    def postgresql_create_user(user, password)
      @@users = nil
      Chef::Log.info("Creating PostgreSQL user \"#{user.name}\".")
      create_query = "CREATE USER #{postgresql_dbh.escape(user.name)} WITH PASSWORD '#{postgresql_dbh.escape(password)}'"
      create_query += " CREATEDB" if user.createdb
      create_query += " CREATEROLE" if user.createrole
      create_query += " NOINHERIT" unless user.inherit
      create_query += " NOLOGIN" unless user.login
      create_query += " SUPERUSER" if user.superuser
      create_query += " VALID UNTIL '#{postgresql_dbh.escape(user.valid_until)}'" if user.valid_until
      
      Chef::Log.debug("PostgreSQL query: #{create_query}")
      postgresql_dbh.query(create_query)
      if user.database && user.database != "" 
        postgresql_alter_database_owner(user.name, user.database)
      end
    end
    
    def  postgresql_drop_user(user)
      @@users = nil
      Chef::Log.info("Dropping PostgreSQL user \"#{user.name}\".")
      query="DROP USER #{postgresql_dbh.escape(user.name)}"
      Chef::Log.debug("PostgreSQL #{query}")
      postgresql_dbh.query(query)
    end
    
    def postgresql_manage_privileges(action, grant, privileges)
      on = grant.on.split(",")
      postgresql_dbh({:db => grant.conn_db}, true)
      privilege_query = if action == :delete
        privileges += ["GRANT OPTION"] if grant.grant_option
        Chef::Log.info("Revoking #{privileges.join(", ")} privileges on #{grant.on} from #{grant.user}")
       "REVOKE #{privileges.join(", ")} ON #{on.join(",")} FROM #{grant.user}" 
      else
        with_grant_option = "WITH GRANT OPTION" if grant.grant_option
        Chef::Log.info("Granting #{privileges.join(", ")} privileges on #{on.join(",")} to #{grant.user} #{with_grant_option}")
        "GRANT #{privileges.join(", ")} ON #{on.join(",")} TO \"#{grant.user}\" #{with_grant_option}"
      end
      Chef::Log.debug("PosgreSQL query: #{privilege_query}")
      postgresql_dbh.query(privilege_query)
    end
    
    def postgresql_manage_grants(action, grant)
      case action
        when :create
        missing_privileges = grant.privileges.split(",")
        postgresql_manage_privileges(:create, grant, missing_privileges)
        when :delete
        unwanted_privileges = grant.privileges.split(",")
        postgresql_manage_privileges(:delete, grant, unwanted_privileges)
      end
    end
    
    def postgresql_force_password(user, password)
      select_query = "SELECT passwd FROM pg_shadow WHERE usename ILIKE '#{postgresql_dbh.escape(user.name)}' " + 
      "AND passwd='md5'||MD5('#{postgresql_dbh.escape(password) + postgresql_dbh.escape(user.name)}')"
      Chef::Log.debug("PostgreSQL query: #{select_query}")
      result = postgresql_dbh.exec(select_query)
      if result.num_tuples == 1
        Chef::Log.debug("PostgreSQL password OK for #{user.name}")
      else
        alter_query = "ALTER USER #{postgresql_dbh.escape(user.name)} WITH PASSWORD '#{postgresql_dbh.escape(password)}'"
        Chef::Log.debug("PostgreSQL query: #{alter_query}")
        Chef::Log.info("Reseting PostgreSQL password of #{user.name}")
        postgresql_dbh.query(alter_query)
      end
    end


    # TODO: finish, not in use yet
    def postgresql_user_privileges(grant)
      handle = postgresql_user_handle(grant, :grant)
      return @@grants[handle] if @@grants && @@grants[handle]
      @@grants ||= {}
      @@grants[handle] = {}
      Chef::Log.debug("MySQL query: SHOW GRANTS FOR #{handle}")
      # TODO don't ignore grant option
      mysql_dbh.query("SHOW GRANTS FOR #{handle}").each { |row|
        if row[0] =~ /\AGRANT (.*) ON [`'"]?(\S+?)[`'"]?(\.\S+)? TO .+\Z/
          @@grants[handle][$2] = $1.split(/,\s*/).map { |p|
            p == "ALL PRIVILEGES" ? "ALL" : p
          }
        end
      }
      @@grants[handle]
    end
    
    private
    
    def postgresql_dbh(options = {}, force_reconnect = false)
      # If force_reconnect true go ahed anyway otherwisei if @@dbh exists return it
      return @@dbh if @@dbh unless force_reconnect  
      require "pg"
      
      # Set defaults
      host = "localhost" if host.nil?
      port = 5432 if port.nil?
      db = "postgres" if db.nil? 
      user = "postgres" if user.nil?
      password = nil
      
      # Set from .pgpass
      File.read("/root/.pgpass").each do |line|
        if line =~ /^\s*[^#]+\w+$/
          host, port, db, user, password = line.split(":")
          break
        end
      end
      
      # Overwrite connection options if needed
      db = options[:db] if options[:db]
      
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
    
    def postgresql_alter_database_owner(owner, database)
      Chef::Log.info("ALTER PostgreSQL database \"#{database}\" owner to \"#{owner}\".")
      alter_query ="ALTER DATABASE #{postgresql_dbh.escape(database)} OWNER TO #{postgresql_dbh.escape(owner)}"
      Chef::Log.debug("PostgreSQL query: #{alter_query}")
      postgresql_dbh.query(alter_query)
    end
    
  end # module PostgreSQL
end
