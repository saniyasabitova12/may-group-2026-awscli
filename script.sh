#!/bin/bash

region="us-east-1"
vpc_cidr="192.168.0.0/16"
subnet1_cidr="192.168.0.0/24"
ami_id="ami-01edba92f9036f76e"

vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --region $region \
     --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=MyVpc}]" \
     --query Vpc.VpcId --output text)

subnet1_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet1_cidr --region $region --query Subnet.SubnetId --output text)

igw_id=$(aws ec2 create-internet-gateway --region $region --query InternetGateway.InternetGatewayId --output text)

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id

rt_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region

aws ec2 associate-route-table --subnet-id $subnet1_id --route-table-id $rt_id --region $region

sg_id=$(aws ec2 create-security-group --group-name EC2SecurityGroup --description "Demo Security Group" --vpc-id $vpc_id --region $region --query GroupId --output text)

aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 run-instances --image-id $ami_id --instance-type t3.micro \
        --key-name my-laptop-key --subnet-id $subnet1_id --security-group-ids $sg_id \
        --user-data file://apache.sh \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=kaizen}]" --region $region
