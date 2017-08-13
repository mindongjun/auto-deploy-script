#!/bin/bash
set -e

# ./2.sh [project_name] [database_password]
cd ~

# Install ruby
if [ -e ~/$1/.ruby-version ]; then
  rv="$(cat ~/$1/.ruby-version)"
else
  rv="2.4.1"
fi
rbenv install -v $rv
rbenv global $rv
ruby -v

# Install Bundler
echo "gem: --no-document" > ~/.gemrc
gem install bundler


# Bundle install && figaro config
cd $1 && bundle install --without development test && bundle exec figaro install && echo "production:" >> ./config/application.yml && echo "  SECRET_KEY_BASE: $(bundle exec rake secret RAILS_ENV=production)" >> ./config/application.yml && echo "  DATABASE_PASSWORD: $2" >> ./config/application.yml && cd ..


# Install passenger & nginx
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates

sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update && sudo apt-get install -y nginx-extras passenger
sudo service nginx start


# passenger & nginx config
sudo sed -i -e '/passenger_ruby/c\passenger_ruby /home/ubuntu/.rbenv/shims/ruby;' /etc/nginx/passenger.conf
sudo sed -i -e 's/\# include \/etc\/nginx\/passenger/include \/etc\/nginx\/passenger/g' /etc/nginx/nginx.conf

sudo sed -i -e "s/root \/var\/www\/html;/root \/home\/ubuntu\/$1\/public; passenger_enabled on; rails_env production;/g" -e '/index.nginx-debian.html/d' -e '/try_files/d' -e '/server_name _;/a\        error_page  500 502 503 504  \/50x.html; location = \/50x.html { root html; }' /etc/nginx/sites-enabled/default

sudo service nginx restart

# Assets precompile & restart
cd $1 && bundle exec rake db:create RAILS_ENV=production && bundle exec rake db:migrate RAILS_ENV=production && bundle exec rake db:seed RAILS_ENV=production && bundle exec rake assets:precompile RAILS_ENV=production && touch tmp/restart.txt
