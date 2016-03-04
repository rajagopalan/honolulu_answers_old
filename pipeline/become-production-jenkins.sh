#!/bin/bash -e

gem install trollop --no-ri --no-rdoc
gem install aws-sdk-core --pre --no-ri --no-rdoc

echo "making $stack_name the new production Jenkins..."

ruby pipeline/bin/route53switch-elb.rb  --subdomain samplepipeline --hostedzone $domain --region $region --stackname $name_of_jenkins_stack
