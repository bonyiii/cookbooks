define :pg_db_def, :action => :enable, :owner => nil, :encoding => "UTF-8" do
  include_recipe "postgresql"
   
  if params[:action] == :enable
    execute "Create database #{params[:name]}" do
      user "root"
      owner = "-O #{params[:owner]}" if params[:owner]
      encoding = "-E #{params[:encoding]}" if params[:encoding]
      command "/usr/bin/createdb #{owner} #{encoding} -U postgres #{params[:name]}"
    end
  else
    execute "Drop database #{params[:name]}" do
      command "/usr/bin/dropdb -U postgres #{params[:name]}"
    end
  end # if
  
end