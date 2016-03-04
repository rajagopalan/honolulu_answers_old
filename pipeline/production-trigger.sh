#!/bin/bash -e
set -e

# look up last successful pipeline instance
gem install aws-sdk-core --pre  --no-ri --no-rdoc

export query="select * from \`$sdb_domain\` where production_candidate = \'true\' and started_at is not null order by started_at desc limit 1"

export pipeline_instance_id=`ruby -e 'require "aws-sdk-core"' -e "puts Aws::SimpleDB.new(region: '$region').select(select_expression: '$query').items.first.name"`

if [[ -z "$pipeline_instance_id" ]]; then
    echo "failed to retrieve info from configuration store."
    exit 1
fi

# push instance id into file so we can load it into the environment
echo pipeline_instance_id=$pipeline_instance_id > environment.txt
echo "Passing these variables into the pipeline"
cat environment.txt