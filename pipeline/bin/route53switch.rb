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

def get_old_ip_address r53, subdomain, hosted_zone_name
   zone_id = get_zone_id r53, hosted_zone_name
   resource_record = r53.list_resource_record_sets(hosted_zone_id: zone_id).resource_record_sets.select {|record| record.name == "#{subdomain}.#{hosted_zone_name}."}
   if (resource_record.nil? || resource_record.empty?) then raise "No resource record exists for #{subdomain}.#{hosted_zone_name}." end
   old_ip_address = resource_record.first.resource_records.first.value
   return old_ip_address
end

def get_new_ip_address cfn, ops, stack_name
  instance_id = get_opsworks_instance_id cfn, stack_name
  new_ip_address = ops.describe_instances(instance_ids: [instance_id]).first.instances.first.public_ip
  return new_ip_address
end

def get_opsworks_instance_id cfn, stack_name
  instance_id = nil
  cfn.describe_stack_resources(stack_name: stack_name).stack_resources.each do |resource|
    if resource.resource_type == "AWS::OpsWorks::Instance"
      instance_id = cfn.describe_stack_resource(stack_name: stack_name, logical_resource_id: resource.logical_resource_id).stack_resource_detail.physical_resource_id
    end
  end
  return instance_id
end

#route 53 and opsworks only run in us-east-1
r53 = Aws::Route53::Client.new(region: "us-east-1")
ops = Aws::OpsWorks::Client.new(region: "us-east-1")
# cfn needs to be in the same region as everything else, tho.
cfn = Aws::CloudFormation::Client.new(region: opts[:region])

# From CloudFormation, get the OpsWorks instance info. From OpsWorks, get the instance public IP.
new_ip_address = get_new_ip_address cfn, ops, opts[:stackname]
# From Route 53, get the IP address of the existing production instance 
old_ip_address = get_old_ip_address r53, opts[:subdomain], opts[:hostedzone]

# Tell Route 53 to switch the new IP in for the old one
full_address = "#{opts[:subdomain]}.#{opts[:hostedzone]}"
zone_id = get_zone_id r53, opts[:hostedzone]
r53.change_resource_record_sets hosted_zone_id: zone_id, change_batch: 
{ 
  changes: [
    {
      action: "DELETE", 
      resource_record_set: {
        name: full_address, 
        type: "A",
        ttl: 300,
        resource_records: [ { value: old_ip_address} ] }
    },
    {
      action: "CREATE", 
      resource_record_set: {
        name: full_address, 
        type: "A",
        ttl: 300,
        resource_records: [ { value: new_ip_address } ]
      } 
    }
  ] 
}
