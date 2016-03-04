#!/bin/bash -e
gem install opendelivery --no-ri --no-rdoc

export SHA=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'SHA'"`
echo checking out revision $SHA
git checkout $SHA

export stack_name=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'stack_name'"`

aws cloudformation delete-stack --stack-name $stack_name --region $region
