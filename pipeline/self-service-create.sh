#!/bin/bash -e

echo checking out revision $SHA
git checkout $SHA

timestamp=`date +%Y%m%d%H%M%S`

gem install trollop opendelivery --no-ri --no-rdoc
gem install aws-sdk-core --pre --no-ri --no-rdoc
export stack_name=HonoluluAnswers-$timestamp
aws cloudformation create-stack --stack-name $stack_name --template-body "`cat pipeline/config/honolulu.template`" --region ${region}  --disable-rollback --capabilities="CAPABILITY_IAM"  --tags Key=owner,Value=$email Key=revision,Value=$SHA \
--parameters \
  ParameterKey=vpc,ParameterValue=$vpc \
  ParameterKey=publicSubnet,ParameterValue=$publicSubnet \
  ParameterKey=privateSubnetA,ParameterValue=$privateSubnetA \
  ParameterKey=privateSubnetB,ParameterValue=$privateSubnetB
  
# make sure we give AWS a chance to actually create the stack...
sleep 30
ruby pipeline/bin/monitor_stack.rb  --stack $stack_name --region ${region}

