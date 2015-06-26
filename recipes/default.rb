include_recipe 'apt'

package 'mysql-client'

package 'mysql-server'

directory node[:mysql][:datadir]  do
	owner 'mysql'
	group 'mysql'
	mode '0755'
 	action :create
end

directory node[:mysql][:logdir]  do
	owner 'mysql'
	group 'mysql'
	mode '0755'
 	action :create
end


service 'mysql' do
  action :enable
end

service 'mysql' do
  action :start
end

execute 'assign root password' do
  command "/usr/bin/mysqladmin -u root password \"#{node[:mysql][:server_root_password]}\""
  action :run
  only_if "/usr/bin/mysql -u root -e 'show databases;'"
end

ruby_block "mysql datadir" do
  block do
    fe = Chef::Util::FileEdit.new("/etc/mysql/my.cnf")
    fe.search_file_replace(/datadir.*/,"datadir         = #{node[:mysql][:datadir]}")
    fe.search_file_replace(/log_error.*/,"log_error = #{node[:mysql][:logdir]}/error.log")
    fe.write_file
  end
end

service "apparmor"

execute "mysql apparmor" do
	command "echo 'alias /var/lib/mysql/ -> /elasticsearch/mysql/,' >> /etc/apparmor.d/tunables/alias"
  action :run
	notifies :restart, "service[apparmor]"
end
