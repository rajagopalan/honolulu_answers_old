#!/bin/bash -e

gem install opendelivery bundler

export SHA=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'SHA'"`
echo checking out revision $SHA
git checkout $SHA

export RAILS_ENV="test"
export BHT_API_KEY="7868d47a7c43908cc80a44738acebb41"

bundle install
bundle exec rake db:drop
bundle exec rake db:setup
bundle exec rake spec

# Run static analysis
gem install brakeman --version 2.1.1
brakeman -o brakeman-output.tabs

ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'furthest_pipeline_stage_completed', 'build'"
ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'production_candidate', 'false'"
