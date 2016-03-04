#!/bin/bash -e
export RAILS_ENV="development"
ruby pipeline/bin/create_database.rb
mv /tmp/database.yml config/database.yml
gem install bundler
bundle install
bundle exec rake db:schema:load
bundle exec rake db:seed
ruby pipeline/bin/create_honolulu_answers_stack.rb --db `cat /tmp/rds_instance`
