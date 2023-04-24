#!/bin/bash -ex

createVpc="vpc_ids"

write_vpc_to_file() {
    echo $AWS_VPC >> $createVpc
}
create_vpc() {

    trap write_vpc_to_file EXIT

    AWS_REGION="US-east-1"
    AWS_VPC="$AWS_REGION"
    #Create VPC -1
    AWS_VPC_ID=$(aws ec2 create-vpc \
                    --cidr-block 10.0.0.0/16 \
                    --query 'Vpc.{VpcId:VpcId}' \
                    --output text)
    AWS_VPC="$AWS_VPC $AWS_VPC_ID"
    echo "Created VPC ID $AWS_VPC_ID"
    # sleep 2

    #Enable DNS hostname for the VPC -2
    aws ec2 modify-vpc-attribute \
            --vpc-id $AWS_VPC_ID \
            --enable-dns-hostnames "{\"Value\":true}"

    #Create public subnet -3
    AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
        --vpc-id $AWS_VPC_ID --cidr-block 10.0.1.0/24 \
        --availability-zone us-east-1a --query 'Subnet.{SubnetId:SubnetId}' \
        --output text)
    AWS_VPC="$AWS_VPC $AWS_SUBNET_PUBLIC_ID"
    echo "Created Subnet public ID $AWS_SUBNET_PUBLIC_ID"
    # sleep 2

    # Enable Auto-assign Public IP on Public Subnet -4
    aws ec2 modify-subnet-attribute \
        --subnet-id $AWS_SUBNET_PUBLIC_ID \
        --map-public-ip-on-launch

    # Create an Internet Gateway -5
    AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
        --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
        --output text)
    AWS_VPC="$AWS_VPC $AWS_INTERNET_GATEWAY_ID"
    echo "Created internet gateway ID $AWS_VPC $AWS_INTERNET_GATEWAY_ID"
    # sleep 2

    # Attach Internet gateway to your VPC -6
    aws ec2 attach-internet-gateway \
        --vpc-id $AWS_VPC_ID \
        --internet-gateway-id $AWS_INTERNET_GATEWAY_ID

    # Create a route table -7
    AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
        --vpc-id $AWS_VPC_ID \
        --query 'RouteTable.{RouteTableId:RouteTableId}' \
        --output text)
    AWS_VPC="$AWS_VPC $AWS_CUSTOM_ROUTE_TABLE_ID"
    echo "Created custom route table ID $AWS_CUSTOM_ROUTE_TABLE_ID"
    # sleep 2

    # Create route to Internet Gateway -8
    aws ec2 create-route \
        --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id $AWS_INTERNET_GATEWAY_ID

    # Associate the public subnet with route table -9
    AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
        --subnet-id $AWS_SUBNET_PUBLIC_ID \
        --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
        --output text | head -1)
    AWS_VPC="$AWS_VPC $AWS_ROUTE_TABLE_ASSOID"
    echo "Created custom route associated ID $AWS_ROUTE_TABLE_ASSOID"
    # sleep 2

    # Create a security group -10
    aws ec2 create-security-group \
        --vpc-id $AWS_VPC_ID \
        --group-name aca-vpc-security-group \
        --description 'aca-vpc non default security group'

    # Get security group ID's -11
    AWS_DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$AWS_VPC_ID" \
        --query 'SecurityGroups[?GroupName == `default`].GroupId' \
        --output text)
    AWS_VPC="$AWS_VPC $AWS_DEFAULT_SECURITY_GROUP_ID"
    echo "Created AWS DEFAULT SECURITY GROUP ID $AWS_DEFAULT_SECURITY_GROUP_ID"
    # sleep 2

    AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$AWS_VPC_ID" \
        --query 'SecurityGroups[?GroupName == `aca-vpc-security-group`].GroupId' \
        --output text)

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
            },
            {
                "IpProtocol": "tcp",
                "FromPort": 80,
                "ToPort": 80,
                "IpRanges": [
                    {
                        "CidrIp": "0.0.0.0/0",
                        "Description": "Allow HTTP"
                    }
                ]
            }
        ]' &&
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
        }]' &&
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

    # add tags -14
    # add tags insrance name  
    aws ec2 create-tags \
        --resources $INSTANCE_ID \
        --tags "Key=Name,Value=TBD"

    # Add a tag to the VPC    
    aws ec2 create-tags \
        --resources $AWS_VPC_ID \
        --tags "Key=Name,Value=aca-vpc-security-group"

    # Add a tag to public subnet
    aws ec2 create-tags \
        --resources $AWS_SUBNET_PUBLIC_ID \
        --tags "Key=Name, Value=aca-vpc-security-group-public-subnet"

    # Add a tag to the Internet-Gateway
    aws ec2 create-tags \
        --resources $AWS_INTERNET_GATEWAY_ID \
        --tags "Key=Name, Value=aca-vpc-security-group-internet-gateway"

    # Add a tag to the default route table
    AWS_DEFAULT_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$AWS_VPC_ID" \
        --query 'RouteTables[?Associations[0].Main != `false`].RouteTableId' \
        --output text)
    AWS_VPC="$AWS_VPC $AWS_DEFAULT_ROUTE_TABLE_ID"
    echo "Created AWS DEFAULT ROUTE TABLE ID $AWS_DEFAULT_ROUTE_TABLE_ID"
    # sleep 2

    CURRENT_TIME=$(date '+%Y-%m-%d_%H-%M-%S')
    AWS_KEY_PAIR_NAME=$(aws ec2 create-key-pair \
        --key-name "key-pair-{$CURRENT_TIME}" \
        --query 'KeyMaterial' \
        --output text > aca-key-pair.pem)
    AWS_VPC="$AWS_VPC $AWS_KEY_PAIR_NAME"
    echo "Created Key Pair is  my-key-pair"
    # sleep 2

    aws describe-key-pair --key-name my-key-pair
    # Add a tag to the default route table
    aws ec2 create-tags \
        --resources $AWS_DEFAULT_ROUTE_TABLE_ID \
        --tags "Key=Name, Value=aca-vpc-security-group-default-route-table"

    # Add a tag to the public route table
    aws ec2 create-tags \
        --resources $AWS_CUSTOM_ROUTE_TABLE_ID \
        --tags "Key=Name, Value=aca-vpc-security-group-public-route-table"

    # Add a tags to security groups
    aws ec2 create-tags \
        --resources $AWS_CUSTOM_SECURITY_GROUP_ID \
        --tags "Key=Name, Value=aca-vpc-security-group-security-group"

    # Add a tag to default security group
    aws ec2 create-tags \
        --resources $AWS_DEFAULT_SECURITY_GROUP_ID \
        --tags "Key=Name, Value=aca-vpc-security-group-default-security-group"

    # Launch an EC2 instance
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

    declare -g AWS_VPC="$AWS_VPC"    

}

create_vpc