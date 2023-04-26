#!/bin/bash

source ./utils/cleanup.sh
source ./utils/functions.sh
source ./utils/install-aws-cli.sh
source ./utils/create-s3-bucket.sh
source ./utils/delete-s3-bucket.sh

source ./jenkins/install_jenkins.sh

set -ex

# Get the values of subnet and security group arguments
SUBNET="$1"
SECURITY_GROUP="$2"

# Check if the SUBNET argument is an ID
if [[ $SUBNET =~ ^subnet-[a-zA-Z0-9]{16}$ ]]; then
    # Check if the security group argument is an ID
    if [[ $SECURITY_GROUP =~ ^sg-[a-zA-Z0-9]{17}$ ]]; then
        # Get the VPC ID of the subnet and security group
        SUBNET_VPC=$(aws ec2 describe-subnets \
            --subnet-ids $SUBNET \
            --query 'Subnets[0].VpcId' \
            --output text)
        SECURITY_GROUP_VPC=$(aws ec2 describe-security-groups \
        --group-ids $SECURITY_GROUP \
        --query 'SecurityGroups[0].VpcId' \
        --output text)

        # Compare the VPC IDs of the subnet and security group
        if [[ $SUBNET_VPC == $SECURITY_GROUP_VPC ]]; then
            echo "VPC ID: $SUBNET_VPC"
        else
            echo "Error: Subnet and Security Group are not in the same VPC."
        fi
    # Check if the security group argument is a port
    elif [[ $SECURITY_GROUP =~ ^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{0,5})|([0-9]{1,4}))$ ]]; then
        # Get the VPC ID of the subnet
        SUBNET_VPC=$(aws ec2 describe-subnets \
        --subnet-ids $SUBNET \
        --query 'Subnets[0].VpcId' \
        --output text)

        # Create a security group in the same VPC as the subnet
        SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name "my-security-group" \
        --description "My security group" \
        --vpc-id "$SUBNET_VPC" &> /dev/null)

        echo "Security group created: $SECURITY_GROUP_ID"
    else
        echo "Error: Security group argument must be an ID or a port number."
    fi
# Check if the subnet argument is private
elif [[ $SUBNET == "private" ]]; then
    # Check if the security group argument is an ID
    if [[ $SECURITY_GROUP =~ ^sg-[a-zA-Z0-9]{17}$ ]]; then
        # Get the VPC ID of the security group
        SECURITY_GROUP_VPC=$(aws ec2 describe-security-groups \
        --group-ids $SECURITY_GROUP \
        --query 'SecurityGroups[0].VpcId' \
        --output text)

        # Create a subnet in the same VPC as the security group
        SUBNET_ID=$(aws ec2 create-subnet \
        --vpc-id "$SECURITY_GROUP_VPC" \
        --cidr-block "10.0.0.0/24" &> /dev/null)

        echo "Subnet created: $SUBNET_ID"
    # if security group is a port
    elif [[ $SECURITY_GROUP =~ ^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{0,5})|([0-9]{1,4}))$ ]]; then
        # Get the VPC ID of the subnet
        SUBNET_VPC=$(aws ec2 describe-subnets \
        --subnet-ids $SUBNET \
        --query 'Subnets[0].VpcId' \
        --output text)

        # Create a security group in the same VPC as the subnet
        create_security_group_rules
        # SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        # --group-name "my-security-group" \
        # --description "My security group" \
        # --vpc-id "$SUBNET_VPC" &> /dev/null)

        echo "Security group created: $AWS_CUSTOM_SECURITY_GROUP_ID"
    else
        echo "Error: Security group argument must be an ID."

    fi
# check if subnet argument is public
elif [[ $SUBNET == "public" ]]; then
    # Check if the security group argument is an ID
    if [[ $SECURITY_GROUP =~ ^sg-[a-zA-Z0-9]{17}$ ]]; then
        # Get the VPC ID of the security group
        SECURITY_GROUP_VPC=$(aws ec2 describe-security-groups \
        --group-ids $SECURITY_GROUP \
        --query 'SecurityGroups[0].VpcId' \
        --output text)

        # Create a subnet in the same VPC as the security group
        create_public_subnet
        # SUBNET_ID=$(aws ec2 create-subnet \
        # --vpc-id "$SECURITY_GROUP_VPC" \
        # --cidr-block "10.0.0.0/24" &> /dev/null)

        echo "Subnet created: $AWS_SUBNET_PUBLIC_ID"

    # check if the security group is port
    elif [[ $SECURITY_GROUP =~ ^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{0,5})|([0-9]{1,4}))$ ]]; then
        # Get the VPC ID of the subnet
        SUBNET_VPC=$(aws ec2 describe-subnets \
        --subnet-ids $SUBNET \
        --query 'Subnets[0].VpcId' \
        --output text)

        # Create a security group in the same VPC as the subnet
        SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name "my-security-group" \
        --description "My security group" \
        --vpc-id "$SUBNET_VPC" &> /dev/null)

        echo "Security group created: $SECURITY_GROUP_ID"
    else
        echo "Error: Security group argument must be an ID."

    fi
# if if first argument is create then create a new vpc group and launch instance
elif [[ $SUBNET == "create" ]]; then
    ./utils/functions.sh
# if argument is delete then delete
elif [[ $SUBNET == "delete" ]]; then
    ./utils/cleanup.sh 

else
  echo "Error: Subnet argument must be private or public"
fi

