## Honolulu Answers Rails/AWS Reference Implementation

We used this repo to demonstrate how to script the Honolulu Answers app to deploy in [Amazon Web Services](https://aws.amazon.com/) (AWS). This fork is not intended to be merged back into the original, and we don't plan on keeping it updated with any changes to made to the original. You will incur AWS charges while resources are in use. Use this application at your own risk!

## Setting up the Honolulu Answers application
#### Prereqs:
* [AWS Access Keys](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSGettingStartedGuide/AWSCredentials.html) ready and enabled.
* [AWS CLI tool](https://aws.amazon.com/cli/) installed and configured. Directions for setting up a development environment with both the AWS CLI tool and Ruby installed can be found [here](https://github.com/rajagopalan/cdsimplified_commons/wiki/Development-Environment-Setup).
 
The AWS CLI tool is configured with the command:

```
aws configure
```

## Complete Pipeline Installation (Recommended):
We have created and recommend the automation for a complete pipeline, using Jenkins, running the Honolulu Answers application.

Follow the directions in our [honolulu-jenkins-cookbook](https://github.com/rajagopalan/honolulu_jenkins_cookbooks) repository.

This will create a VPC, two private subnets, a public subnet, a Jenkins load balancer, an application load balancer, and the following instances:
* Bastion host
* NAT server
* Jenkins server
* Rails-app server (c3.large)

## Honolulu Answers Standalone Deployment:

First of all, clone the repository:

```
sudo yum -y install git
git clone https://github.com/rajagopalan/honolulu_answers.git
cd honolulu_answers/
```

The application can be launched along with a VPC or you can launch it into your own VPC.
### Create the VPC and the Honolulu Application Stack

The following command will create a VPC for you. It will create the VPC, two private subnets, a public subnet, a NAT server, and a Bastion host. You will need to provide a key pair name for Bastion SSH access. (You can find the CloudFormation code at [vpc_and_honolulu.template](https://github.com/rajagopalan/honolulu_answers/blob/master/pipeline/config/vpc_and_honolulu.template))

```
aws cloudformation create-stack --stack-name HonoluluAnswers --template-body "`cat pipeline/config/vpc_and_honolulu.template`" --region <your_region> --disable-rollback --capabilities="CAPABILITY_IAM" --parameters ParameterKey=KeyName,ParameterValue="<key_name>"
```

**Parameters**
* **stack-name**: You can name the stack anything you'd like.
* **region**: The region to deploy the stack. Must be same region as the key pair used. A list of regions and availability zones can be found [here](http://www.cdsimplified.com/cloud/list-all-the-availability-zones/). Example: us-west-2
* **KeyName**: The name of the Key Pair that will be used to access the created Bastion host. See [Creating an EC2 Key Pair](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-keypair.html).  


### Create the Honolulu Application Stack providing your VPC
To launch the application into your own VPC, the VPC must contain two private subnets and a public subnet. Provide the subnet and VPC ids to the following command: (You can find the CloudFormation code at [honolulu.template](https://github.com/rajagopalan/honolulu_answers/blob/master/pipeline/config/honolulu.template))

```
aws cloudformation create-stack --stack-name HonoluluAnswers --template-body "`cat pipeline/config/honolulu.template`" --region us-west-2  --disable-rollback --capabilities="CAPABILITY_IAM" --parameters ParameterKey=vpc,ParameterValue="<your_vpc_id>" ParameterKey=privateSubnetA,ParameterValue="<your_first_private_subnet_id>" ParameterKey=privateSubnetB,ParameterValue="<your_second_private_subnet_id>" ParameterKey=publicSubnet,ParameterValue="<your_public_subnet_id>" 
```

**Parameters**
* **stack-name**: You can name the stack anything you'd like.
* **region**: The region to deploy the stack. Must be same region as the key pair used. A list of regions and availability zones can be found [here](http://www.cdsimplified.com/cloud/list-all-the-availability-zones/). Example: us-west-2
* **vpc**: The id of the VPC of which to deploy the stack. Find them in _AWS Console->VPC->Your VPCs_. Example: vpc-1a2b3c4d
* **privateSubnetA**: A private subnet in the VPC above. Find it in _AWS Console->VPC->Subnets_. Example: subnet-5a6b7c8d
* **privateSubnetB**: Another private subnet in the VPC above. Find it in _AWS Console->VPC->Subnets_. Example: subnet-1234adcd
* **privateSubnetA**: A public subnet in the VPC above. Find it in _AWS Console->VPC->Subnets_. Example: subnet-01dc23ba

#### Optional Parameters
You can optionally overwrite the following parameters in either stack, whether or not you provide VPC/Subnets.
After --parameters you can add any or all of the following parameters in the format:  ParameterKey=<key_listed_below>,ParameterValue="<your_value>"
* **DBUser**: User for the DB created for the Honolulu Answers application. Default: "honolulu".
* **DBPassword**: Password for the DB User. Default: "password".
* **DBName**: Name of the DB created. Default: "honoluluanswers".
* **SearchifyApiURL**: URL to a Searchify account. Default: "http://:oh5H697EC1TRlc@2zqe.api.searchify.com".
* **SearchifyIndex**: The index of Searchify to use. Default: "hnlgovanswers-dev"

## Accessing the Honolulu Answers Application
After about 50 minutes, an Opsworks stack is created and launched. To get details:

1. Log into the [OpsWorks](http://console.aws.amazon.com/opsworks) console
1. You should see an OpsWorks stack listed named **Honolulu Answers** -- click on it. If you see more than one listed (because you kicked it off a few times), they are listed in alphabetical-then-chronological order. So the last *Honolulu Answers* stack listed will be the most recent one.
1. Click on **Instances** within the OpsWorks stack you selected.
1. Once the Instance turns green and shows its status as *Online*, click on **Layers** on the left.
1. Click the link in the ELB Layer and the Honolulu Answers application will load!

### Deleting provisioned AWS resources
* Go to the [CloudFormation](http://console.aws.amazon.com/cloudformation) console and delete the corresponding CloudFormation stack.

### Changes made to this Github Fork

We made several changes to this repository, you can view them here: [Stelligent Changes to the Honolulu Answers Application](https://github.com/rajagopalan/honolulu_answers/wiki/Stelligent-Changes-to-the-Honolulu-Answers-Application)

### Tools Used

We're using a bunch of great tools for automating and running this application. You can view the list here: [Tools Used](https://github.com/rajagopalan/honolulu_answers/wiki/Tools-Used)

## Resources
### Working Systems

NOTE: The links below may or may not be operational at any given time.

* [pipelinedemo.elasticoperations.com](http://pipelinedemo.elasticoperations.com/) - Working Continous Integration Server. To setup your own Jenkins server based on the same open source scripts, go to [Launching a Jenkins Environment](https://github.com/rajagopalan/honolulu_jenkins_cookbooks/wiki/Launching-a-Jenkins-Environment).
* [appdemo.elasticoperations.com](http://appdemo.elasticoperations.com/) - Working Honolulu Answers application based on the automation described in this README.

### Diagrams
We've put together several diagrams to help show how everything ties together. You can view them here: [Architecture and Design](https://github.com/rajagopalan/honolulu_answers/wiki/Architecture-and-Design)
