#!/bin/bash 

set -ex

# Get the values of subnet and security group arguments
SUBNET="$1"
SECURITY_GROUP="$2"

# Check if the SUBNET argument is an ID
if [[ $SUBNET =~ ^subnet-[a-zA-Z0-9]+$ ]]; then
    # Check if the security group argument is an ID
    if [[ $SECURITY_GROUP =~ ^sg-[a-zA-Z0-9]+$ ]]; then
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
    elif [[ $SECURITY_GROUP =~ ^[0-9]+$ ]]; then
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
# Check if the subnet argument is priv/pub
elif [[ $SUBNET == "private" || $SUBNET == "public" ]]; then
    # Check if the security group argument is an ID
    if [[ $SECURITY_GROUP =~ ^sg-[a-zA-Z0-9]+$ ]]; then
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
    else

    echo "Error: Security group argument must be an ID."

    fi
else
  echo "Error: Subnet argument must be private or public"
fi

