#!/bin/bash

# Disable AWS CLI pager to prevent opening less
export AWS_PAGER=""

# Exit on any error
set -e

# Variables
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
VPC_NAME="MyVPC"
IGW_NAME="MyVPC-IGW"
PUBLIC_RT_NAME="MyVPC-PublicRT"
PRIVATE_RT_NAME="MyVPC-PrivateRT"
NAT_GW_NAME="MyVPC-NATGW"

# Subnet CIDR blocks
PUBLIC_SUBNETS=(
  "10.0.1.0/24 us-east-1a PublicSubnet1"
  "10.0.2.0/24 us-east-1b PublicSubnet2"
  "10.0.3.0/24 us-east-1c PublicSubnet3"
  "10.0.4.0/24 us-east-1d PublicSubnet4"
)
PRIVATE_SUBNETS=(
  "10.0.11.0/24 us-east-1a PrivateSubnet1"
  "10.0.12.0/24 us-east-1b PrivateSubnet2"
  "10.0.13.0/24 us-east-1c PrivateSubnet3"
  "10.0.14.0/24 us-east-1d PrivateSubnet4"
)

echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --query Vpc.VpcId \
  --output text)
aws ec2 create-tags \
  --resources $VPC_ID \
  --tags Key=Name,Value=$VPC_NAME \
  --region $REGION
echo "VPC created with ID: $VPC_ID"

echo "Enabling DNS support and hostnames..."
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support \
  --region $REGION
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames \
  --region $REGION
echo "DNS support and hostnames enabled"

echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --query InternetGateway.InternetGatewayId \
  --output text)
aws ec2 create-tags \
  --resources $IGW_ID \
  --tags Key=Name,Value=$IGW_NAME \
  --region $REGION
echo "Internet Gateway created with ID: $IGW_ID"

echo "Attaching Internet Gateway to VPC..."
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $REGION
echo "Internet Gateway attached"

echo "Creating public route table..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query RouteTable.RouteTableId \
  --output text)
aws ec2 create-tags \
  --resources $PUBLIC_RT_ID \
  --tags Key=Name,Value=$PUBLIC_RT_NAME \
  --region $REGION
echo "Public route table created with ID: $PUBLIC_RT_ID"

echo "Adding route to Internet Gateway..."
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION
echo "Route added"

echo "Creating private route table..."
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query RouteTable.RouteTableId \
  --output text)
aws ec2 create-tags \
  --resources $PRIVATE_RT_ID \
  --tags Key=Name,Value=$PRIVATE_RT_NAME \
  --region $REGION
echo "Private route table created with ID: $PRIVATE_RT_ID"

echo "Creating public subnets..."
PUBLIC_SUBNET_IDS=()
for SUBNET in "${PUBLIC_SUBNETS[@]}"; do
  read CIDR AZ NAME <<< $SUBNET
  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $CIDR \
    --availability-zone $AZ \
    --region $REGION \
    --query Subnet.SubnetId \
    --output text)
  aws ec2 create-tags \
    --resources $SUBNET_ID \
    --tags Key=Name,Value=$NAME \
    --region $REGION
  aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET_ID \
    --map-public-ip-on-launch \
    --region $REGION
  aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID \
    --route-table-id $PUBLIC_RT_ID \
    --region $REGION
  PUBLIC_SUBNET_IDS+=($SUBNET_ID)
  echo "Created public subnet $NAME in $AZ with ID: $SUBNET_ID"
done

echo "Creating NAT Gateway in first public subnet..."
EIP_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --region $REGION \
  --query AllocationId \
  --output text)
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id ${PUBLIC_SUBNET_IDS[0]} \
  --allocation-id $EIP_ID \
  --region $REGION \
  --query NatGateway.NatGatewayId \
  --output text)
aws ec2 create-tags \
  --resources $NAT_GW_ID \
  --tags Key=Name,Value=$NAT_GW_NAME \
  --region $REGION
echo "NAT Gateway created with ID: $NAT_GW_ID"

echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available \
  --nat-gateway-ids $NAT_GW_ID \
  --region $REGION
echo "NAT Gateway is available"

echo "Adding route to NAT Gateway in private route table..."
aws ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID \
  --region $REGION
echo "Route added"

echo "Creating private subnets..."
for SUBNET in "${PRIVATE_SUBNETS[@]}"; do
  read CIDR AZ NAME <<< $SUBNET
  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $CIDR \
    --availability-zone $AZ \
    --region $REGION \
    --query Subnet.SubnetId \
    --output text)
  aws ec2 create-tags \
    --resources $SUBNET_ID \
    --tags Key=Name,Value=$NAME \
    --region $REGION
  aws ec2 associate-route-table \
    --subnet-id $SUBNET_ID \
    --route-table-id $PRIVATE_RT_ID \
    --region $REGION
  echo "Created private subnet $NAME in $AZ with ID: $SUBNET_ID"
done

echo "VPC setup complete!"
