#!/bin/bash -e

export SHA=`ruby -e 'require "opendelivery"' -e "puts OpenDelivery::Domain.new('$region').get_property '$sdb_domain','$pipeline_instance_id', 'SHA'"`
echo checking out revision $SHA
git checkout $SHA

gem install trollop opendelivery --no-ri --no-rdoc
gem install aws-sdk-core --pre --no-ri --no-rdoc
export stack_name=HonoluluAnswers-Production-`date +%Y%m%d%H%M%S`
aws cloudformation create-stack --stack-name $stack_name --template-body "`cat pipeline/config/honolulu.template`" --region ${region}  --disable-rollback --capabilities="CAPABILITY_IAM" \
--parameters \
  ParameterKey=vpc,ParameterValue=$vpc \
  ParameterKey=publicSubnet,ParameterValue=$publicSubnet \
  ParameterKey=privateSubnetA,ParameterValue=$privateSubnetA \
  ParameterKey=privateSubnetB,ParameterValue=$privateSubnetB
  
ruby pipeline/bin/monitor_stack.rb  --stack $stack_name --region ${region}

ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'production_stack_name', '$stack_name'"