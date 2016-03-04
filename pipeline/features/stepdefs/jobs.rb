require 'aws-sdk-core'
require 'nokogiri'

When(/^I inspect the config for "(.*?)"$/) do |job|
  output_lines = run_cmd.run "cat /var/lib/jenkins/jobs/#{job}/config.xml"

  @xml_doc = Nokogiri::XML(output_lines)
end

Then(/^I should see multiscm configured for that job$/) do
  nodes = @xml_doc.xpath("//scm[@class='org.jenkinsci.plugins.multiplescms.MultiSCM']")
  nodes.size.should == 1
  nodes = @xml_doc.xpath("//scm/scms/scm[@class='hudson.plugins.git.GitSCM']")
  nodes.size.should == 2
  nodes = @xml_doc.xpath("//scm/scms/scm/userRemoteConfigs/hudson.plugins.git.UserRemoteConfig/url")
  nodes.size.should == 2
end

Then(/^I should see emails turned on for that job$/) do
  nodes = @xml_doc.xpath("//publishers/hudson.plugins.emailext.ExtendedEmailPublisher")
  nodes.size.should == 1
  nodes = @xml_doc.xpath("//publishers/hudson.plugins.emailext.ExtendedEmailPublisher/configuredTriggers/hudson.plugins.emailext.plugins.trigger.FailureTrigger")
  nodes.size.should == 1
  nodes = @xml_doc.xpath("//publishers/hudson.plugins.emailext.ExtendedEmailPublisher/configuredTriggers/hudson.plugins.emailext.plugins.trigger.FixedTrigger")
  nodes.size.should == 1
end

Then(/^I should see that the build step is run in an RVM managed environment$/) do
  nodes = @xml_doc.xpath("//buildWrappers/ruby-proxy-object/ruby-object/object/impl[@pluginid='rvm']")
  nodes.size.should == 1
end

Then(/^I should see that each job has Delivery Pipeline configuration$/) do
  nodes = @xml_doc.xpath("//buildWrappers/ruby-proxy-object/ruby-object/object/impl[@pluginid='rvm']")
  nodes.size.should == 1
end

Then(/^I should see that it takes the parameter "(.*?)"$/) do |arg1|
  nodes = @xml_doc.xpath("/project/properties/hudson.model.ParametersDefinitionProperty/parameterDefinitions/hudson.model.StringParameterDefinition[name='#{arg1}']")
  nodes.size.should == 1
end


Then(/^I should see success emails turned on for that job$/) do
  nodes = @xml_doc.xpath("//publishers/hudson.plugins.emailext.ExtendedEmailPublisher")
  nodes.size.should == 1
  nodes = @xml_doc.xpath("//publishers/hudson.plugins.emailext.ExtendedEmailPublisher/configuredTriggers/hudson.plugins.emailext.plugins.trigger.SuccessTrigger")
  nodes.size.should == 1
end

