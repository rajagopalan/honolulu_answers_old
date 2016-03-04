require 'pp'
require 'trollop'
require 'aws-sdk-core'
require 'opendelivery'

opts = Trollop::options do
  opt :region, "The region that you're working in.", :type => String, :required => true
  opt :sdbdomain, "SimpleDB domain", :type => String, :required => true
  opt :pipelineid, "ID of the pipeline to check", :type => String, :required => true
  opt :check, "Name of the attribute to check", :type => String, :required => true
end

def is_accepted?(gate_control)
  if gate_control != nil && gate_control.downcase == "accept"
    true
  end
end

def is_rejected?(gate_control)
  if gate_control != nil && gate_control.downcase != "accept"
    true
  end
end


while true
  gate_control = OpenDelivery::Domain.new(opts[:region]).get_property(opts[:sdbdomain], opts[:pipelineid], opts[:check])
  sleep 60
  if is_accepted?(gate_control)
    puts "Accepted"
    exit 0
  elsif is_rejected?(gate_control)
    puts "Rejected"
    exit 1
  end
  puts "Sleeping and waiting"
end
