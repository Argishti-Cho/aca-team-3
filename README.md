# aca-team-3

AWS EC2 Instance, S3 Bucket, and Jenkins Installation
This repository contains a set of scripts to automate the creation of an EC2 instance on AWS, set up an S3 bucket for data storage, and install Jenkins, a popular continuous integration and delivery tool and has cleanup tool for all instances

Pre-requisites
Before you begin, you will need to have an AWS account and an IAM user with the necessary permissions to create EC2 instances and S3 buckets. You will also need to install the AWS CLI and have access keys configured for your IAM user.

Getting Started
To create an EC2 instance, S3 bucket, and install Jenkins, follow these steps:

Run the aws_ec2_instance.sh script to create the EC2 instance.

Update the create-s3-bucket.sh script with your AWS configuration and the necessary details for your S3 bucket.

Run the create-s3-bucket.sh script to create the S3 bucket.

Update the install_jenkins.sh script with your AWS configuration and the necessary details for your Jenkins installation.

Run the install_jenkins.sh script to install Jenkins on your EC2 instance.

Step 1: run manage.sh and give arguments
Option 1: run manage.sh with argument create to launch an EC2 instance
Option 2: run manage.sh with argument delete with argument $2 INSTANCE_ID to delete an EC2 instance
Option 3: run manage.sh Subnet ID manage.sh automatically checks the subnet ID and will show if it has an VPC ID associated
Option 4: give argument "private" or "public" and manage.sh will automatically check the private or public IP address and will show if it has an IP address associated

Contributing
If you find any issues with these scripts or would like to contribute to their development, please feel free to submit a pull request or open an issue on this repository.

License
This repository is licensed under the MIT License. See LICENSE for more information.

You may be interested in visiting Troubleshooting CodePipeline - AWS CodePipeline.

