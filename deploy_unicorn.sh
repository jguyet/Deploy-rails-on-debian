##
# DOCKERS COMMANDS
##

#docker-machine create skillz
#docker-machine env skillz

#docker pull debian:jessie
#docker run -it -p 80:80 --rm --name "skill-container" "debian:jessie" "/bin/bash"

##
# VPS INSTALLATION
##

#in shell of container
apt-get update
apt-get --yes --force-yes install curl
apt-get --yes --force-yes install vim
apt-get --yes --force-yes install nodejs
apt-get --yes --force-yes install git
apt-get --yes --force-yes install nginx

#install public key of RVM
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

#install RVM
curl -sSL https://get.rvm.io | bash

#export rvm paths
source /usr/local/rvm/scripts/rvm

#ruby 2.5.0
rvm install 2.5.0
gem install rails

#download rails project
cd /home
git clone https://github.com/jguyet/rush-ruby.git
cd /home/rush-ruby/rush
bundle install
rake db:migration
rake db:seeds
rake assets:precompile

export SECRET_KEY_BASE=`rake secret`

#create shared sockets and logs directory for nginx
mkdir -p shared/pids shared/sockets shared/log

################################################################################
#                              UNICORN SERVER
################################################################################
echo "gem 'unicorn'" >> Gemfile

bundle install

echo '# set path to application
app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/shared"
working_directory app_dir


# Set unicorn options
worker_processes 2
preload_app true
timeout 30

# Set up socket location
listen "#{shared_dir}/sockets/unicorn.sock", :backlog => 64

# Logging
stderr_path "#{shared_dir}/log/unicorn.stderr.log"
stdout_path "#{shared_dir}/log/unicorn.stdout.log"

# Set master PID location
pid "#{shared_dir}/pids/unicorn.pid"' > config/unicorn.rb

#add nginx configuration
echo 'upstream app {
	server unix:/home/rush-ruby/rush/shared/sockets/unicorn.sock fail_timeout=0;
}

server {
	listen 3000 default_server;
	listen [::]:3000 default_server;

	root /home/rush-ruby/rush/public;

	try_files $uri/index.html $uri @app;

	location @app {
		proxy_pass http://app;
	}
}
' > /etc/nginx/sites-available/default

#start unicorn server
bundle exec unicorn -c config/unicorn.rb&

################################################################################

#start nginx
service nginx restart

# connect you on your docker-machine IP:8080
# its deployed
