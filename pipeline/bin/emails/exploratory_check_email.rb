require 'trollop'
require 'aws-sdk-core'

opts = Trollop::options do
  opt :region, "The region that you're working in.", :type => String, :required => true
  opt :pipelineid, "ID of the pipeline to email", :type => String, :required => true
  opt :recipient, "Email address of intended email recipient", :type => String, :required => true
  opt :sender, "Email address of sender", :type => String, :required => true
  opt :jenkinsurl, "Url to access jenkins on", :type => String, :required => true
  opt :gitsha, "Git SHA used", :type => String, :required => true
  opt :application, "Name of application", :type => String, :required => true
end

Aws.config[:region] = opts[:region]
ses = Aws::SES::Client.new

resp = ses.send_email(
  # required
  source: opts[:sender],
  # required
  destination: {
    to_addresses: [opts[:recipient]]
  },
  # required
  message: {
    # required
    subject: {
      # required
      data: "A #{opts[:application]} environment has passed the acceptance stage and is ready for exploratory testing!",
      charset: "utf-8",
    },
    # required
    body: {
      html: {
        # required
        data: "
\n
<p>The acceptance stage of your continuous delivery pipeline has completed and is ready for some more exploratory testing. Create a <a href=\"#{opts[:jenkinsurl]}/job/self-service-create-dsl/build\">self service environment</a> with the Git SHA listed below, and run your exploratory tests.</p>

<p><strong>Git SHA:</strong> #{opts[:gitsha]}</p>

<p>After testing the environment, run the <a href=\"#{opts[:jenkinsurl]}/job/exploratory-control/build\">exploratory-control job</a> with the pipeline instance id listed below, and approve or deny the pipeline to proceed to further stages.</p>
\n
<p><strong>Pipeline Instance ID:</strong> #{opts[:pipelineid]}</p>
\n",
        charset: "utf-8",
      }
    }
  }
)
