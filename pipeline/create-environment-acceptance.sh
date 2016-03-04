#!/bin/bash -e

export SHA=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'SHA'"`
export timestamp=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'started_at'"`
echo checking out revision $SHA
git checkout $SHA



gem install trollop opendelivery --no-ri --no-rdoc
gem install aws-sdk-core --pre --no-ri --no-rdoc
export stack_name=HonoluluAnswers-$timestamp
ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'stack_name', '$stack_name'"
aws cloudformation create-stack --stack-name $stack_name --template-body "`cat pipeline/config/honolulu.template`" --region ${region}  --disable-rollback --capabilities="CAPABILITY_IAM" \
--parameters \
  ParameterKey=vpc,ParameterValue=$vpc \
  ParameterKey=publicSubnet,ParameterValue=$publicSubnet \
  ParameterKey=privateSubnetA,ParameterValue=$privateSubnetA \
  ParameterKey=privateSubnetB,ParameterValue=$privateSubnetB

# make sure we give AWS a chance to actually create the stack...
sleep 30
ruby pipeline/bin/monitor_stack.rb  --stack $stack_name --region ${region}

ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'furthest_pipeline_stage_completed', 'build-and-deploy'"
