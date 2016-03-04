require "aws-sdk-core"

Given(/^I have the CloudFormation stack information to query$/) do
  # the name of the cloudformation stack and the region we're operating should be environment variables
  @stackname = ENV["stack_name"]
  expect(@stackname).to be, "$stack_name wasn't set in the local environment"
  region = ENV["region"]
  expect(region).to be, "$region wasn't set in the local environment"

  # poll cfn for instance ID
  cfn = Aws::CloudFormation::Client.new region: region
  elb = Aws::ElasticLoadBalancing::Client.new region: region

  @address = elb.describe_load_balancers(load_balancer_names: cfn.describe_stack_resources(stack_name: @stackname).stack_resources.collect {|rsc| if rsc.resource_type == "AWS::ElasticLoadBalancing::LoadBalancer" then rsc.physical_resource_id end }.compact).load_balancer_descriptions.first.dns_name
  
  expect(@address).to be, "No ELB address associated with stack."
end


When(/^I pull up the Honolulu Answers application$/) do
  @error = nil
  begin
    # the trailing / is important!!
    url = "http://#{@address}/"
    @response = Net::HTTP.get_response(URI.parse(url).host, URI.parse(url).path)
  rescue Exception => e
    @error = e
  end
end

Then(/^I should get data back$/) do
    expect(@failure).to eq(nil), "An error occured when trying to open the application: #{@failure}"
    expect(@response.code).to eql("200"), "Non 200 code returned"
    expect(@response.body.length).to be > 0, "No data receieved"
end
