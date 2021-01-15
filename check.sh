#!/bin/bash
read -p "Enter IPv4 CIDR block:" cidr_block
read -p "Enter your key name: " key_name
read -p "Enter your key value: " key_value
vpc_id=`aws ec2 create-vpc --cidr-block=$cidr_block --tag-specifications 'ResourceType=vpc,Tags=[{Key='$key_name',Value='$key_value'}]' --query Vpc.VpcId --output text`
read -p "Enter IPv4 CIDR block for public subnet: " public_cidr_block
read -p "Enter your public key name: " public_key_name
read -p "Enter your public key value: " public_key_value
public_subnet_id=`aws ec2 create-subnet --vpc-id $vpc_id --cidr-block=$public_cidr_block --tag-specifications 'ResourceType=subnet,Tags=[{Key='$public_key_name',Value='$public_key_value'}]' --query Subnet.SubnetId --output text`
read -p "Enter IPv4 CIDR block for private subnet: " private_cidr_block
read -p "Enter your private key name: " private_key_name
read -p "Enter your private key value: " private_key_value
private_subnet_id=`aws ec2 create-subnet --vpc-id $vpc_id --cidr-block=$private_cidr_block --tag-specifications 'ResourceType=subnet,Tags=[{Key='$private_key_name',Value='$private_key_value'}]' --query Subnet.SubnetId --output text`
read -p "Enter your internet gateway key name: " igw_key_name
read -p "Enter your internet gateway key value: " igw_key_value
igw_id=`aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key='$igw_key_name',Value='$igw_key_value'}]' --query InternetGateway.InternetGatewayId --output text`
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
read -p "Enter your public route table key name: " public_rt_key_name
read -p "Enter your public route table key value: " public_rt_key_value
public_rt=`aws ec2 create-route-table --vpc-id $vpc_id --tag-specifications 'ResourceType=route-table,Tags=[{Key='$public_rt_key_name',Value='$public_rt_key_value'}]' --query RouteTable.RouteTableId --output text`
read -p "Enter your private route table key name: " private_rt_key_name
read -p "Enter your private route table key value: " private_rt_key_value
private_rt=`aws ec2 create-route-table --vpc-id $vpc_id --tag-specifications 'ResourceType=route-table,Tags=[{Key='$private_rt_key_name',Value='$private_rt_key_value'}]' --query RouteTable.RouteTableId --output text`
aws ec2 create-route --route-table-id $public_rt --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id
aws ec2 associate-route-table --route-table-id $public_rt --subnet-id $public_subnet_id
aws ec2 associate-route-table --route-table-id $private_rt --subnet-id $private_subnet_id
read -p "Enter your NAT instance security group name: " nat_sg_name
read -p "Enter your NAT instance security group key name: " nat_sg_key_name
read -p "Enter your NAT instance security group key value: " nat_sg_key_value
nat_sg_id=`aws ec2 create-security-group --group-name $nat_sg_name --description "NAT security group" --vpc-id $vpc_id --tag-specifications 'ResourceType=security-group,Tags=[{Key='$nat_sg_key_name',Value='$nat_sg_key_value'}]' --query GroupId --output text`
read -p "Enter your ip address: " my_ip
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol tcp --port 80 --cidr $private_cidr_block
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol tcp --port 22 --cidr $my_ip
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol tcp --port 443 --cidr $private_cidr_block
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol icmp --port -1 --cidr $private_cidr_block
read -p "Enter your public instance security group name: " public_sg_name
read -p "Enter your public instance security group key name: " public_sg_key_name
read -p "Enter your public instance security group key value: " public_sg_key_value
public_sg_id=`aws ec2 create-security-group --group-name $public_sg_name --description "public security group" --vpc-id $vpc_id --tag-specifications 'ResourceType=security-group,Tags=[{Key='$public_sg_key_name',Value='$public_sg_key_value'}]' --query GroupId --output text`
aws ec2 authorize-security-group-ingress --group-id $public_sg_id --protocol tcp --port 80 --cidr $my_ip
aws ec2 authorize-security-group-ingress --group-id $public_sg_id --protocol tcp --port 22 --cidr $my_ip
aws ec2 authorize-security-group-ingress --group-id $public_sg_id --protocol tcp --port 443 --cidr $my_ip
read -p "Enter your private instance security group name: " private_sg_name
read -p "Enter your private instance security group key name: " private_sg_key_name
read -p "Enter your private instance security group key value: " private_sg_key_value
private_sg_id=`aws ec2 create-security-group --group-name $private_sg_name --description "private security group" --vpc-id $vpc_id --tag-specifications 'ResourceType=security-group,Tags=[{Key='$private_sg_key_name',Value='$private_sg_key_value'}]' --query GroupId --output text`
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 80 --cidr $my_ip
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 8080 --source-group $public_sg_id
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol all --port all --source-group $nat_sg_id
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 22 --cidr $my_ip
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 22 --cidr $public_cidr_block
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 443 --cidr $my_ip
read -p "Enter name for your key pair: " key_pair
aws ec2 create-key-pair --key-name $key_pair --query 'KeyMaterial' --output text > $key_pair
read -p "Enter your nat instance ami id: " nat_ami_id
read -p "Enter your nat instance key name: " nat_instance_key_name
read -p "Enter your nat instance key value: " nat_instance_key_value
aws ec2 run-instances --image-id $nat_ami_id --count 1 --instance-type t2.micro --key-name $key_pair --subnet-id $public_subnet_id --security-group-ids $nat_sg_id --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key='$nat_instance_key_name',Value='$nat_instance_key_value'}]'
read -p "Enter your public instance ami id: " public_ami_id
read -p "Enter your public instance key name: " public_instance_key_name
read -p "Enter your public instance key value: " public_instance_key_value
aws ec2 run-instances --image-id $public_ami_id --count 1 --instance-type t2.micro --key-name $key_pair --subnet-id $public_subnet_id --security-group-ids $public_sg_id --associate-public-ip-address  --tag-specifications 'ResourceType=instance,Tags=[{Key='$public_instance_key_name',Value='$public_instance_key_value'}]' 
read -p "Enter your private instance ami id: " private_ami_id
read -p "Enter your private instance key name: " private_instance_key_name
read -p "Enter your private instance key value: " private_instance_key_value
aws ec2 run-instances --image-id $private_ami_id --count 1 --instance-type t2.micro --key-name $key_pair --subnet-id $private_subnet_id --security-group-ids $private_sg_id --associate-public-ip-address  --tag-specifications 'ResourceType=instance,Tags=[{Key='$private_instance_key_name',Value='$private_instance_key_value'}]' 

