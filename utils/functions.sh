#!/bin/bash -ex

createVpc="vpc_ids" # this puts all ID's in the vpc_ids file

# this function will create a file and will add AWS_VPS to that file
write_vpc_to_file() {
    echo $AWS_VPC >> $createVpc
}

AWS_REGION="US-east-1"
AWS_VPC="$AWS_REGION"
AWS_VPC_ID=""
AWS_KEY_PAIR_NAME=""
AWS_CUSTOM_SECURITY_GROUP_ID=""
AWS_SUBNET_PUBLIC_ID=""
CUSTOM_TCP=""

# 1
#creating the VPC
create_vpc(){

    AWS_VPC_ID=$(aws ec2 create-vpc \
                    --cidr-block 10.0.0.0/16 \
                    --query 'Vpc.{VpcId:VpcId}' \
                    --output text)
    AWS_VPC="$AWS_VPC $AWS_VPC_ID"
    echo "Created VPC ID $AWS_VPC_ID"
}
# create_vpc
# echo "VPC ID: $AWS_VPC_ID"

##############################################################

# 2
#Enable DNS hostname for the VPC
enable_dns_hostname() {

    if [ -z "$AWS_VPC_ID" ]; then
        echo "There is no VPC ID please create one \
                and then call this function!"
        exit 1
    else
        aws ec2 modify-vpc-attribute \
                --vpc-id $AWS_VPC_ID \
                --enable-dns-hostnames "{\"Value\":true}"
    fi

}
# enable_dns_hostname

##############################################################

# 3
#Create public subnet
create_public_subnet() {

    if [ -z "$AWS_VPC_ID" ]; then
        echo "There is no VPC ID please create one \
                and then call this function!"
        exit 1
    else
        AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
            --vpc-id $AWS_VPC_ID \
            --cidr-block 10.0.1.0/24 \
            --availability-zone us-east-1a \
            --query 'Subnet.{SubnetId:SubnetId}' \
            --output text)
        AWS_VPC="$AWS_VPC $AWS_SUBNET_PUBLIC_ID"
        echo "Created Subnet public ID $AWS_SUBNET_PUBLIC_ID"

        # Enable Auto-assign Public IP on Public Subnet
        aws ec2 modify-subnet-attribute \
            --subnet-id $AWS_SUBNET_PUBLIC_ID \
            --map-public-ip-on-launch "{\"Value\":true}"
    fi
    # Add a tag to public subnet
    aws ec2 create-tags \
        --resources $AWS_SUBNET_PUBLIC_ID \
        --tags "Key=Name, Value=aca--public-subnet"
}
# create_public_subnet

##############################################################

# 4
# Create an Internet Gateway
create_internet_gateway() {

    if [ -z "$AWS_VPC_ID" ]; then
        echo "There is no VPC ID please create one \
                and then call this function!"
        exit 1
    else
        AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
            --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
            --output text)
        AWS_VPC="$AWS_VPC $AWS_INTERNET_GATEWAY_ID"
        echo "Created internet gateway ID $AWS_INTERNET_GATEWAY_ID"

        # Attach Internet gateway to your VPC
        aws ec2 attach-internet-gateway \
            --vpc-id $AWS_VPC_ID \
            --internet-gateway-id $AWS_INTERNET_GATEWAY_ID
    fi
    # Add a tag to the Internet-Gateway
    aws ec2 create-tags \
        --resources $AWS_INTERNET_GATEWAY_ID \
        --tags "Key=Name, Value=aca-internet-gateway"
}
# create_internet_gateway

##############################################################

# 5
# Create a route table and internet gateway with association
create_rt_and_ig_with_associate() {

    if [ -z "$AWS_VPC_ID" ]; then
        echo "There is no VPC ID please create one \
                and then call this function!"
        exit 1
    else
        # create a custom route table
        AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
            --vpc-id $AWS_VPC_ID \
            --query 'RouteTable.{RouteTableId:RouteTableId}' \
            --output text)
        AWS_VPC="$AWS_VPC $AWS_CUSTOM_ROUTE_TABLE_ID"
        echo "Created custom route table ID $AWS_CUSTOM_ROUTE_TABLE_ID"

        # Create route to Internet Gateway
        aws ec2 create-route \
            --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
            --destination-cidr-block 0.0.0.0/0 \
            --gateway-id $AWS_INTERNET_GATEWAY_ID
        if [[ -z "$AWS_SUBNET_PUBLIC_ID" ]]; then
            echo "There is no subnet ID please create one \
                    and then call this function!"
            exit 1
        else
            # Associate the public subnet with route table -9
            AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
                --subnet-id $AWS_SUBNET_PUBLIC_ID \
                --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
                --output text | head -1)
            AWS_VPC="$AWS_VPC $AWS_ROUTE_TABLE_ASSOID"
            echo "Created custom route associated ID $AWS_ROUTE_TABLE_ASSOID"
        fi
    fi
    # Add a tag to the public route table
    aws ec2 create-tags \
        --resources $AWS_CUSTOM_ROUTE_TABLE_ID \
        --tags "Key=Name, Value=aca-public-route-table"

}
# create_rt_and_ig_with_associate

##############################################################

#6
# Create a security group
create_security_group_rules() {
    if [ -z "$AWS_VPC_ID" ]; then
        echo "There is no VPC ID please create one \
                and then call this function!"
        exit 1
    else 
        AWS_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
            --vpc-id $AWS_VPC_ID \
            --group-name aca-security-group \
            --description 'ACA security group' \
            --tag-specifications 'ResourceType=security-group, \
                Tags=[{Key=Name,Value=ACA-SecurityGroup}]')

        # Get security group ID

        # uncomment if you dont't want custom security groups
        # AWS_DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        #     --filters "Name=vpc-id,Values=$AWS_VPC_ID" \
        #     --query 'SecurityGroups[?GroupName == `default`].GroupId' \
        #     --output text)
        # AWS_VPC="$AWS_VPC $AWS_DEFAULT_SECURITY_GROUP_ID"
        # echo "Created AWS DEFAULT SECURITY GROUP ID $AWS_DEFAULT_SECURITY_GROUP_ID"

        # customize security group rules
        # comment if you don't want customize security groups
        AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
            --filters "Name=vpc-id,Values=$AWS_VPC_ID" \
            --query 'SecurityGroups[?GroupName == `aca-custom-security-group`].GroupId' \
            --tag-specifications 'ResourceType=security-group, \
                Tags=[{Key=Name,Value=ACA-Custom-SecurityGroup}]'
            --output text)
        AWS_VPC="$AWS_VPC $AWS_CUSTOM_SECURITY_GROUP_ID"
        echo "Created AWS CUSTOM SECURITY GROUP ID $AWS_CUSTOM_SECURITY_GROUP_ID"

        # Create security group ingress rules -12
        aws ec2 authorize-security-group-ingress \
            --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
            --ip-permissions '[
                {
                    "IpProtocol": "tcp",
                    "FromPort": 22,
                    "ToPort": 22,
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0",
                            "Description": "Allow SSH"
                        }
                    ]
                }]' &&
        aws ec2 authorize-security-group-ingress \
            --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
            --ip-permissions '[{
                "IpProtocol": "tcp", 
                "FromPort": 443, 
                "ToPort": 443, 
                "IpRanges": [
                    {
                        "CidrIp": "0.0.0.0/0", 
                        "Description": "Allow HTTPS"
                    }
                ]
            }]' 
            &&
        # uncomment for HTTP access
        # aws ec2 authorize-security-group-ingress \
        #     --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
        #     --ip-permissions '[{
        #             "IpProtocol": "tcp",
        #             "FromPort": 80,
        #             "ToPort": 80,
        #             "IpRanges": [
        #                 {
        #                     "CidrIp": "0.0.0.0/0",
        #                     "Description": "Allow HTTP"
        #                 }
        #             ]
        #         }]' 
        #     &&
        aws ec2 authorize-security-group-ingress \
            --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
            --ip-permissions '[{
                "IpProtocol": "tcp",
                "FromPort": 8000,
                "ToPort": 8000,
                "IpRanges": [
                    {
                        "CidrIp": "0.0.0.0/0",
                        "Description": "Custom Port"
                    }
                ]
            }]'
            # &&
        # uncomment for any CUSTOM TCP access
        # aws ec2 authorize-security-group-ingress \
        #     --group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
        #     --ip-permissions '[{
        #         "IpProtocol": "tcp",
        #         "FromPort": $CUSTOM_TCP, 
        #         "ToPort": $CUSTOM_TCP,
        #         "IpRanges": [
        #             {
        #                 "CidrIp": "0.0.0.0/0",
        #                 "Description": "Custom Port"
        #             }
        #         ]
        #     }]'
    fi
}
# create_security_group_rules

##############################################################

# 7
# creatre Key-pair for security
create_key_pair() {

    CURRENT_TIME=$(date '+%Y-%m-%d_%H-%M-%S')
    KEY_PAIR_NAME="key-pair-$CURRENT_TIME"
    AWS_KEY_PAIR_NAME=$(aws ec2 create-key-pair \
        --key-name $KEY_PAIR_NAME \
        --query 'KeyMaterial' \
        --output text > aca-key-pair.pem)
    AWS_VPC="$AWS_VPC $AWS_KEY_PAIR_NAME"
    echo "Created Key pair is  $KEY_PAIR_NAME"
    aws describe-key-pairs --key-name $KEY_PAIR_NAME
}
# create_key_pair

##############################################################

# 8
# Launch an EC2 instance
# customize valume size and other parameters if needed
launch_instance() {

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-0c55b159cbfafe1f0 \
        --count 1 --instance-type t2.micro \
        --key-name $AWS_KEY_PAIR_NAME \
        --security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
        --subnet-id $AWS_SUBNET_PUBLIC_ID \
        --associate-public-ip-address \
        --query 'Instances[0].InstanceId' \
        --region $AWS_REGION \
        --block-device-mappings '[{
            "DeviceName":"/dev/xvda",
            "Ebs":{"VolumeSize":8,
            "VolumeType":"gp2"}
            }]' \
        --output text)

    # Wait for the instance to start
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    # Print the public IP address of the instance
    PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

    echo "Instance created with public IP address: $PUBLIC_IP"
}


trap write_vpc_to_file EXIT