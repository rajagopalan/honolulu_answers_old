#!/bin/bash -e

gem install opendelivery  --no-ri --no-rdoc

export SHA=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'SHA'"`
echo checking out revision $SHA
git checkout $SHA

export production_stack_name=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'production_stack_name'"`

ruby pipeline/bin/route53switch-elb.rb  --subdomain honolulu --hostedzone $domain --region $region --stackname $production_stack_name
ruby pipeline/bin/route53switch-elb.rb  --subdomain appdemo --hostedzone $domain --region $region --stackname $production_stack_name
ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'furthest_pipeline_stage_completed', 'bluegreen'"

