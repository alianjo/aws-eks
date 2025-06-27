# main.tf

# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# --- VPC and Networking Setup ---

# Create a new VPC for the EKS cluster
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  count             = 2 # We need 2 public subnets
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index) # Allocate specific CIDRs for public
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Instances in public subnets get public IPs

  tags = {
    Name                                = "${var.cluster_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" # Required for EKS auto-discovery
    "kubernetes.io/role/elb"            = "1" # Required for ELB to discover public subnets
  }
}

# Create private subnets
resource "aws_subnet" "private_subnets" {
  count             = 2 # We need 2 private subnets
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2) # Allocate specific CIDRs for private (after public)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                = "${var.cluster_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" # Required for EKS auto-discovery
    "kubernetes.io/role/internal-elb"   = "1" # Required for internal ELB to discover private subnets
  }
}

# Create Internet Gateway for public subnet access
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  depends_on = [aws_internet_gateway.eks_igw] # Ensure IGW exists before EIP for NAT GW

  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }
}

resource "aws_eip" "nat_gateway_eip_2" {
  depends_on = [aws_internet_gateway.eks_igw] # Ensure IGW exists before EIP for NAT GW

  tags = {
    Name = "${var.cluster_name}-nat-eip-2"
  }
}

# Create NAT Gateway in a public subnet for private subnet outbound internet access
resource "aws_nat_gateway" "eks_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id # Place NAT GW in the first public subnet

  tags = {
    Name = "${var.cluster_name}-nat-gateway"
  }

  # Ensure the NAT Gateway is created after the public subnet is available
  depends_on = [aws_internet_gateway.eks_igw]
}

# Create Second NAT Gateway in a public subnet for private subnet outbound internet access
resource "aws_nat_gateway" "eks_nat_gateway_2" {
  allocation_id = aws_eip.nat_gateway_eip_2.id
  subnet_id     = aws_subnet.public_subnets[1].id # Place NAT GW in the first public subnet

  tags = {
    Name = "${var.cluster_name}-nat-gateway-2"
  }

  # Ensure the NAT Gateway is created after the public subnet is available
  depends_on = [aws_internet_gateway.eks_igw]
}

# Create public route table and associate with public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_route_table_associations" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Create private route table and associate with private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_nat_gateway.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_route_table_associations" {
  subnet_id      = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_nat_gateway_2.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt-2"
  }
}

resource "aws_route_table_association" "private_route_table_associations_2" {
  subnet_id      = aws_subnet.private_subnets[1].id
  route_table_id = aws_route_table.private_route_table_2.id
}


# --- EKS Cluster Setup ---

# IAM role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"
  }
}

# Attach policies to EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment_1" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment_2" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# Current AWS partition for ARN construction
data "aws_partition" "current" {}


# EKS Cluster resource
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids             = flatten([aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id])
    endpoint_private_access = false # Set to true for private access only
    endpoint_public_access  = true  # Set to false for private access only
  }

  # Ensure the cluster is created after the VPC and subnets are ready
  depends_on = [
    aws_route_table_association.public_route_table_associations,
    aws_route_table_association.private_route_table_associations,
    aws_route_table_association.private_route_table_associations_2,
  ]

  tags = {
    Name = var.cluster_name
  }
}

# IAM role for EKS Node Group
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.cluster_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-eks-node-group-role"
  }
}

# Attach policies to EKS Node Group Role
resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment_1" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment_2" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment_3" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

# EKS Managed Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id # Deploy nodes into private subnets
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  # Ensure node group is created after the cluster is active
  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]

  tags = {
    Name = "${var.cluster_name}-node-group"
  }
}