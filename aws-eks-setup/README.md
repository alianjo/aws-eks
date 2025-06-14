# AWS EKS Setup

This repository contains a script to set up an Amazon EKS cluster with a properly configured VPC infrastructure.

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. eksctl installed
3. kubectl installed
4. AWS account with appropriate permissions

## Quick Start

1. Clone this repository:
```bash
git clone <repository-url>
cd aws-eks-setup
```

2. Make the setup script executable:
```bash
chmod +x setup.sh
```

3. Run the setup script:
```bash
./setup.sh
```

The script will:
- Create a VPC with public and private subnets across 4 availability zones
- Set up NAT Gateway for private subnet internet access
- Create an EKS cluster with managed node groups
- Configure all necessary networking components

## Configuration

You can modify the following variables in `setup.sh` to customize your setup:
- `REGION`: AWS region (default: us-east-1)
- `VPC_CIDR`: VPC CIDR block (default: 10.0.0.0/16)
- `CLUSTER_NAME`: Name of your EKS cluster (default: my-eks-cluster)

## After Setup

Once the setup is complete, configure kubectl:
```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-east-1
```

## Cleanup

To delete the EKS cluster and all associated resources:
```bash
eksctl delete cluster --name my-eks-cluster --region us-east-1
```

## Architecture

The setup creates:
- 1 VPC
- 4 Public Subnets (one per AZ)
- 4 Private Subnets (one per AZ)
- 1 Internet Gateway
- 1 NAT Gateway
- 1 EKS Cluster with managed node groups 