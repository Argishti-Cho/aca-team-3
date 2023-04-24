#!/bin/bash

# delete existing instances

#tbd after every tag

clean_ec2() {
  INSTANCE_IDS=$(aws ec2 describe-instances \ 
    --filters "Name=tag:Name,Values=TBD" \
    --query 'Reservations[].Instances[].InstanceId' \ 
    --output text)	
 
  if [ -z "$INSTANCE_IDS" ]; then
        echo "No instances found with name TBD"
        return
    fi

    for INSTANCE_ID in $INSTANCE_IDS; do
            aws ec2 terminate-instances \
            --instance-ids "$INSTANCE_ID"
            aws ec2 wait instance-terminated \
            --instance-ids "$INSTANCE_ID"
            if [ $? -eq 0 ]; then
                echo "EC2 instance $INSTANCE_ID successfully terminated"
            else
                echo "Error terminate instance"
            fi
    done
}

clean_subnets_rtbs() {
  SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=MySubnet*" --query 'Subnets[].SubnetId' --output text)

  if [ -z "$SUBNET_IDS" ]; then
	echo "No subnets found with name EC2"
    return
  fi

  for SUBNET_ID in $SUBNET_IDS; do
	aws ec2 delete-subnet --subnet-id "$SUBNET_ID"
    		if [ $? -eq 0 ]; then
      			echo "Subnet $SUBNET_ID deleted"
		else
                		echo "Error deleting subnet"
    		fi
  done

    RTB_IDS=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=MyRTB" --query 'RouteTables[].RouteTableId' --output text)

    if [ -z "$RTB_IDSS" ]; then
   	echo "No Route Tables found with name MyRTB"
       return
    fi

    for RTB_ID in $RTB_IDS; do
	  aws ec2 delete-route-table --route-table-id "$RTB_ID"
 		 if [ $? -eq 0 ]; then
 			   echo "Route table $RTB_ID deleted"
		 else
                			 echo "Error deleting RTB"
  		 fi
   done
}
clean_igw() {
  IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=MyIGW" --query 'InternetGateways[0].InternetGatewayId' --output text)
  VPC_ID=$(aws ec2 describe-internet-gateways --internet-gateway-id "$IGW_ID" --query 'InternetGateways[].Attachments[].VpcId' --output text)

  if [ -z "$IGW_ID" ]; then
	echo "No Internet Gateways found by name MyIGW"
	return
  fi

  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
  
  if [ "$?" -ne 0 ]; then
  	echo "Internet gateway $IGW_ID detached from VPC $VPC_ID"
	else
		echo "There is no internet gateway to detach"
  fi

  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
  if [ $? -eq 0 ]; then
    echo "Internet gateway $IGW_ID deleted"
  else
                echo "Error deleting IGW"
  fi
}

clean_sg() {

  SG_IDS=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=MySG" --query 'SecurityGroups[].GroupId' --output text)
	
  if [ -z "$SG_IDS" ]; then
	echo "No security groups found with name My-SG"
		return
  fi

  for SG_ID in $SG_IDS; do

  	for DEP_ID in $(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$SG_ID" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text); do
        aws ec2 detach-network-interface --attachment-id $(aws ec2 describe-network-interfaces --network-interface-id $DEP_ID --query 'NetworkInterfaces[].Attachment.AttachmentId' --output text)
        aws ec2 wait network-interface-available --network-interface-ids $DEP_ID
   	done

     aws ec2 delete-security-group --group-id $SG_ID
        if [ $? -eq 0 ]; then
                echo "Security group $SG_ID successfully deleted"
	else
                	echo "Error deleting SG"
        fi
  done
}
 
clean_vpc() {
  VPC_IDS=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=MyVPC" --query 'Vpcs[].VpcId' --output text)
  
  for VPC_ID in $VPC_IDS; do
     aws ec2 delete-vpc --vpc-id "$VPC_ID"
  	if [ $? -eq 0 ]; then
    		echo "VPC $VPC_ID deleted"
	else
                	echo "Error deleting VPC"
 	fi

  done
}