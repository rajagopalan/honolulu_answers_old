require 'trollop'
require 'aws-sdk-core'

opts = Trollop::options do
  opt :region, "The region that you're working in.", :type => String, :required => true
  opt :stackname, "The name of the CloudFormation stack that is intended to become the new production stack", :type => String, :required => true
end

stack_name = opts[:stackname]

Aws.config[:region] = opts[:region]
cfn = Aws::CloudFormation::Client.new
ops = Aws::OpsWorks::Client.new
elb = Aws::ElasticLoadBalancing::Client.new
ec2 = Aws::EC2::Client.new

url = nil
ops_stack_id = nil
layers_and_instances = Hash.new {|h,k| h[k] = [] }

resources = cfn.list_stack_resources stack_name: stack_name

resources.stack_resource_summaries.each do |resource|
  case resource.resource_type
  when "AWS::ElasticLoadBalancing::LoadBalancer"
    dns_name = elb.describe_load_balancers(load_balancer_names: [resource.physical_resource_id]).load_balancer_descriptions.first.dns_name
    url = "http://#{dns_name}/SodaPurchase/test.html"
  when "AWS::OpsWorks::Stack"
    ops_stack_id = resource.physical_resource_id
  when "AWS::OpsWorks::Instance"
    instance_id = ops.describe_instances(instance_ids: [resource.physical_resource_id]).instances.first.ec2_instance_id
    ip = ec2.describe_instances(instance_ids: [instance_id]).reservations.first.instances.first.public_ip_address
    layer_ids = ops.describe_instances(instance_ids: [resource.physical_resource_id]).instances.first.layer_ids
    layer_name = ops.describe_layers(layer_ids: layer_ids).layers.first.name
    layers_and_instances[layer_name] << ip
  end
end


File.open "environment.txt", 'w' do |f|
  f.puts "export URL=#{url}"
  f.puts "export OPSWORKS_STACK_ID=#{ops_stack_id}"
end
