#!/bin/bash -e

# generate pipeline instance id
timestamp=`date +%Y%m%d%H%M%S`
export pipeline_instance_id=$timestamp-$BUILD_NUMBER
echo pipeline_instance_id=$pipeline_instance_id

# lookup the SHA of the latest commit
GIT_SHA=`git log | head -1 | awk '{ print $2 }'`

# save instance id to SDB
ruby -v
gem install opendelivery --no-ri --no-rdoc
ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'SHA', '$GIT_SHA'"
ruby -e 'require "opendelivery"' -e "OpenDelivery::Domain.new('$region').set_property '$sdb_domain','$pipeline_instance_id', 'started_at', '$timestamp'"

# push instance id into file so we can load it into the environment
echo pipeline_instance_id=$pipeline_instance_id > environment.txt
