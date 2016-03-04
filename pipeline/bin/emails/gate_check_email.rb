require 'trollop'
require 'aws-sdk-core'

opts = Trollop::options do
  opt :region, "The region that you're working in.", :type => String, :required => true
  opt :pipelineid, "ID of the pipeline to email", :type => String, :required => true
  opt :recipient, "Email address of tntended email recipient", :type => String, :required => true
  opt :sender, "Email address of sender", :type => String, :required => true
  opt :jenkinsurl, "Url to access jenkins on", :type => String, :required => true
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
      data: "The #{opts[:application]} environment #{opts[:pipelineid]} is a production candidate!",
      charset: "utf-8",
    },
    # required
    body: {
      html: {
        # required
        data: "
\n
<p>The in-depth testing of your pipeline have completed successfully. This environment is now a production candidate. Run the <a href=\"#{opts[:jenkinsurl]}/job/preprod-control/build\">preprod-control job</a> with the pipeline instance id listed below and approve or deny the pipeline to proceed to further stages.</p>
\n
<p><strong>Pipeline Instance ID:</strong> #{opts[:pipelineid]}</p>
\n",
        charset: "utf-8",
      }
    }
  }
)
