module Opscode
  module PostgreSQL
    
    @@dbh = nil
    @@users = nil
    @@grants = nil
    @@databases = nil
    
    private
    
    def mysql_dbh
      return @@dbh if @@dbh
      require 'postgres'
      host = "localhost"
      password = nil
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
      @@dbh = ::PGconn.connect(host, "postgres", password)
    end
  end
  
end
