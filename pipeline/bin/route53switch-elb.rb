require 'pp'
require 'trollop'
require 'aws-sdk-core'

opts = Trollop::options do
  opt :subdomain, "The sub-domain that should be switched to point to the new address (just the subdomain. For example, for demo.elasticoperations.com, you'd punch in 'demo')", :type => String, :required => true
  opt :hostedzone, "The hosted zone name that should be switched to point to the new address (This is the domain. For example, for demo.elasticoperations.com, you'd punch in 'elasticoperations.com')", :type => String, :required => true
  opt :region, "The region that you're working in.", :type => String, :required => true
  opt :stackname, "The name of the CloudFormation stack that is intended to become the new production stack", :type => String, :required => true
end

def get_zone_id r53, hosted_zone_name
  zone_id = r53.list_hosted_zones.hosted_zones.collect {|zone| if zone.name == "#{hosted_zone_name}." then zone.id.split('/').last end }.compact.first
  return zone_id
end

def get_new_elb_address cfn, elb, stack_name
  elb_address = elb.describe_load_balancers(load_balancer_names: cfn.describe_stack_resources(stack_name: stack_name).stack_resources.collect {|rsc| if rsc.resource_type == "AWS::ElasticLoadBalancing::LoadBalancer" then rsc.physical_resource_id end }.compact).load_balancer_descriptions.first.dns_name
  return elb_address
end

#route 53 and opsworks only run in us-east-1
r53 = Aws::Route53::Client.new(region: "us-east-1")
# cfn needs to be in the same region as everything else, tho.
elb = Aws::ElasticLoadBalancing::Client.new(region: opts[:region])
cfn = Aws::CloudFormation::Client.new(region: opts[:region])

# From CloudFormation, get the OpsWorks instance info. From OpsWorks, get the instance public IP.
new_elb_address = get_new_elb_address cfn, elb, opts[:stackname]

# Tell Route 53 to switch the new IP in for the old one
full_address = "#{opts[:subdomain]}.#{opts[:hostedzone]}"
zone_id = get_zone_id r53, opts[:hostedzone]
r53.change_resource_record_sets hosted_zone_id: zone_id, change_batch: 
{ 
  changes: [
    {
      action: "UPSERT", 
      resource_record_set: {
        name: full_address, 
        type: "CNAME",
        ttl: 300,
        resource_records: [ { value: new_elb_address} ] }
    }
  ] 
}
