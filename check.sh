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
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol tcp --port 80 --cidr $private_cidr_block
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol tcp --port 443 --cidr $private_cidr_block
aws ec2 authorize-security-group-ingress --group-id $nat_sg_id --protocol icmp --port -1 --cidr $private_cidr_block
read -p "Enter your public instance security group name: " public_sg_name
read -p "Enter your public instance security group key name: " public_sg_key_name
read -p "Enter your public instance security group key value: " public_sg_key_value
public_sg_id=`aws ec2 create-security-group --group-name $public_sg_name --description "public security group" --vpc-id $vpc_id --tag-specifications 'ResourceType=security-group,Tags=[{Key='$public_sg_key_name',Value='$public_sg_key_value'}]' --query GroupId --output text`
aws ec2 authorize-security-group-ingress --group-id $public_sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $public_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $public_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
read -p "Enter your private instance security group name: " private_sg_name
read -p "Enter your private instance security group key name: " private_sg_key_name
read -p "Enter your private instance security group key value: " private_sg_key_value
private_sg_id=`aws ec2 create-security-group --group-name $private_sg_name --description "private security group" --vpc-id $vpc_id --tag-specifications 'ResourceType=security-group,Tags=[{Key='$private_sg_key_name',Value='$private_sg_key_value'}]' --query GroupId --output text`
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 8080 --source-group $public_sg_id
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol all --port all --source-group $nat_sg_id
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 22 --cidr $public_cidr_block
aws ec2 authorize-security-group-ingress --group-id $private_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
read -p "Enter name for your key pair: " key_pair
aws ec2 create-key-pair --key-name $key_pair --query 'KeyMaterial' --output text > $key_pair
sudo chmod 600 $key_pair
read -p "Enter your nat instance ami id: " nat_ami_id
read -p "Enter your nat instance key name: " nat_instance_key_name
read -p "Enter your nat instance key value: " nat_instance_key_value
aws ec2 run-instances --image-id $nat_ami_id --count 1 --instance-type t2.micro --key-name $key_pair --subnet-id $public_subnet_id --security-group-ids $nat_sg_id --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key='$nat_instance_key_name',Value='$nat_instance_key_value'}]' 
read -p "Enter your nat instance id that you have created: " nat_instance_id
aws ec2 create-route --route-table-id $private_rt --destination-cidr-block 0.0.0.0/0 --instance-id $nat_instance_id
aws ec2 modify-instance-attribute  --instance-id $nat_instance_id --source-dest-check | --no-source-dest-check
read -p "Enter your public instance ami id: " public_ami_id
read -p "Enter your public instance key name: " public_instance_key_name
read -p "Enter your public instance key value: " public_instance_key_value
aws ec2 run-instances --image-id $public_ami_id --count 1 --instance-type t2.micro --key-name $key_pair --subnet-id $public_subnet_id --security-group-ids $public_sg_id --associate-public-ip-address  --tag-specifications 'ResourceType=instance,Tags=[{Key='$public_instance_key_name',Value='$public_instance_key_value'}]' 
read -p "Enter your private instance ami id: " private_ami_id
read -p "Enter your private instance key name: " private_instance_key_name
read -p "Enter your private instance key value: " private_instance_key_value
aws ec2 run-instances --image-id $private_ami_id --count 1 --instance-type t2.micro --key-name $key_pair --subnet-id $private_subnet_id --security-group-ids $private_sg_id --associate-public-ip-address  --tag-specifications 'ResourceType=instance,Tags=[{Key='$private_instance_key_name',Value='$private_instance_key_value'}]' 
read -p "Enter your public ip for ssh: " public_ip
ssh -i ec2-user@$public_ip $key_pair
ssh -i $key_pair ec2-user@$public_ip sudo yum install httpd
ssh -i $key_pair ec2-user@$public_ip sudo yum install -y mod_ssl
ssh -i $key_pair ec2-user@$public_ip read -p 'Enter your key name for ssl certificate: ' name
ssh -i $key_pair ec2-user@$public_ip read -p 'Enter the org name for ssl certificate: ' name
ssh -i $key_pair ec2-user@$public_ip sudo openssl genrsa -des3 -out $name.key 1024 
ssh -i $key_pair ec2-user@$public_ip sudo openssl req -new -key $name.key -out $name.csr
ssh -i $key_pair ec2-user@$public_ip sudo cp $name.key $name.key.org
ssh -i $key_pair ec2-user@$public_ip sudo openssl rsa -in $name.key.org -out $name.key
ssh -i $key_pair ec2-user@$public_ip sudo openssl x509 -req -days 365 -in $name.csr -signkey $name.key -out $name.crt
ssh -i $key_pair ec2-user@$public_ip sudo mv $name.* /etc/pki/tls/certs/ 
ssh -i $key_pair ec2-user@$public_ip read -p 'Enter your conf file name: ' virtualhost 
ssh -i $key_pair ec2-user@$public_ip read -p 'Enter ServerName: ' servername
ssh -i $key_pair ec2-user@$public_ip read -p 'Enter serverAlias: ' serveralias 
ssh -i $key_pair ec2-user@$public_ip sudo touch $virtualhost
ssh -i $key_pair ec2-user@$public_ip sudo chmod 666 $virtualhost
ssh -i $key_pair ec2-user@$public_ip read -p 'Enter your private IP: ' private_ip
ssh -i $key_pair ec2-user@$public_ip echo "<VirtualHost *:443>" >>$virtualhost 
ssh -i $key_pair ec2-user@$public_ip echo "          ServerAdmin webmaster@localhost">>$virtualhost 
ssh -i $key_pair ec2-user@$public_ip echo "          ServerName "$servername>>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          ServerAlias "$serveralias>>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          DocumentRoot /var/www/html/">>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          SSLEngine on">>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          SSLCertificateFile /etc/pki/tls/certs/"$name.crt>>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          SSLCertificateKeyFile /etc/pki/tls/certs/"$name.key>>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          ">>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          SSLProxyEngine on">>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          ProxyPass / http://"$private_ip":8080/">>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "          ProxyPassReverse / http://"$private_ip":8080/">>$virtualhost
ssh -i $key_pair ec2-user@$public_ip echo "</VirtualHost>">>$virtualhost
ssh -i $key_pair ec2-user@$public_ip sudo chmod 666 /etc/httpd/conf.d/$virtualhost.conf
ssh -i $key_pair ec2-user@$public_ip sudo cp $virtualhost /etc/httpd/conf.d/$virtualhost.conf 
ssh -i $key_pair ec2-user@$public_ip sudo chmod 666 /etc/hosts 
ssh -i $key_pair ec2-user@$public_ip echo $public_ip" " $servername>>/etc/hosts
ssh -i $key_pair ec2-user@$public_ip sudo chmod 644 /etc/hosts
ssh -i $key_pair ec2-user@$private_ip sudo yum install java
ssh -i $key_pair ec2-user@$private_ip sudo wget https://downloads.apache.org/tomcat/tomcat-8/v8.5.61/bin/apache-tomcat-8.5.61.tar.gz
ssh -i $key_pair ec2-user@$private_ip sudo tar -xvf apache-tomcat-8.5.61.tar.gz
ssh -i $key_pair ec2-user@$private_ip sudo wget https://get.jenkins.io/war/2.272/jenkins.war
ssh -i $key_pair ec2-user@$private_ip sudo chmod 755 /home/ec2-user/apache-tomcat-8.5.61/webapps/
ssh -i $key_pair ec2-user@$private_ip sudo mv /home/ec2-user/jenkins.war /home/ec2-user/apache-tomcat-8.5.61/webapps/
sudo systemctl start httpd
ssh -i $key_pair ec2-user@$private_ip sudo chmod +x /home/ec2-user/apache-tomcat-8.5.61/bin/
ssh -i $key_pair ec2-user@$private_ip cd /apache-tomcat-8.5.61/bin && sudo chmod +x startup.sh && sudo chmod +x shutdown.sh && sudo ./startup.sh
 

