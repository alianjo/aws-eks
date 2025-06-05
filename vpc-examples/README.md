# AWS VPC Setup for EKS Cluster

This project provides a bash script (`create-vpc.sh`) to create an AWS VPC with public and private subnets, configured for hosting an Amazon EKS (Elastic Kubernetes Service) cluster. The setup includes an Internet Gateway, a NAT Gateway, and separate route tables for public and private subnets, ensuring proper network isolation and connectivity.

## Architecture Overview

The script creates a VPC in the `us-east-1` region with the following components:

- **VPC**: A Virtual Private Cloud with CIDR block `10.0.0.0/16`, named `MyVPC`.
- **Public Subnets**: Four subnets across Availability Zones (AZs) `us-east-1a` to `us-east-1d`, with CIDR blocks `10.0.1.0/24` to `10.0.4.0/24`, named `PublicSubnet1` to `PublicSubnet4`. These subnets have public IP assignment enabled and are associated with a public route table.
- **Private Subnets**: Four subnets across the same AZs, with CIDR blocks `10.0.11.0/24` to `10.0.14.0/24`, named `PrivateSubnet1` to `PrivateSubnet4`. These are associated with a private route table for EKS worker nodes.
- **Internet Gateway (IGW)**: Named `MyVPC-IGW`, attached to the VPC to allow public subnets to access the internet.
- **NAT Gateway**: Deployed in `PublicSubnet1` (us-east-1a) with an Elastic IP, named `MyVPC-NATGW`. It enables private subnets to access the internet for outbound traffic (e.g., EKS control plane communication, container image pulls).
- **Route Tables**:
  - **Public Route Table** (`MyVPC-PublicRT`): Routes traffic from public subnets to the Internet Gateway (`0.0.0.0/0 -> igw-id`).
  - **Private Route Table** (`MyVPC-PrivateRT`): Routes traffic from private subnets to the NAT Gateway (`0.0.0.0/0 -> nat-id`) for outbound internet access.
- **DNS Support**: Enabled for the VPC, with DNS hostnames also enabled, which is required for EKS cluster communication.

This architecture is designed for high availability across four AZs, with public subnets for resources like load balancers and private subnets for EKS worker nodes, ensuring security and scalability.

## Architecture Diagram

Below is an ASCII representation of the VPC architecture:

```
+--------------------------- AWS Cloud (us-east-1) -----------------------------------------------------+
|                                                                                                       |
|  +----------------------------- MyVPC (10.0.0.0/16) ---------------------+  |
|  |                                                                      |  |
|  |  +----------------+  +----------------+  +----------------+  +----------------+  |
|  |  | PublicSubnet1  |  | PublicSubnet2  |  | PublicSubnet3  |  | PublicSubnet4  |  |
|  |  | 10.0.1.0/24   |  | 10.0.2.0/24   |  | 10.0.3.0/24   |  | 10.0.4.0/24   |  |
|  |  | us-east-1a     |  | us-east-1b     |  | us-east-1c     |  | us-east-1d     |  |
|  |  |  +---------+   |  |                |  |                |  |                |  |
|  |  |  |NAT GW   |   |  |                |  |                |  |                |  |
|  |  |  |MyVPC-NATGW| |  |                |  |                |  |                |  |
|  |  |  +---------+   |  |                |  |                |  |                |  |
|  |  +----------------+  +----------------+  +----------------+  +----------------+  |
|  |      |                     |                     |                     |        |
|  |      +---------------------+-------------------------------------------+        |
|  |                    |                     |                     |                 |
|  |                    v                     v                     v                 |
|  |  +--------------------------------+  +--------------------------------+        |
|  |  | Public Route Table (MyVPC-PublicRT)                             |        |
|  |  | 0.0.0.0/0 -> Internet Gateway (MyVPC-IGW)                       |        |
|  |  +----------------------------------------------------------------+        |
|  |                                                                            |
|  |  +----------------+  +----------------+  +----------------+  +----------------+  |
|  |  | PrivateSubnet1 |  | PrivateSubnet2 |  | PrivateSubnet3 |  | PrivateSubnet4 |  |
|  |  | 10.0.11.0/24  |  | 10.0.12.0/24  |  | 10.0.13.0/24  |  | 10.0.14.0/24  |  |
|  |  | us-east-1a    |  | us-east-1b    |  | us-east-1c    |  | us-east-1d    |  |
|  |  | (EKS Nodes)   |  | (EKS Nodes)   |  | (EKS Nodes)   |  | (EKS Nodes)   |  |
|  |  +----------------+  +----------------+  +----------------+  +----------------+  |
|  |      |                     |                     |                     |        |
|  |      +---------------------+-------------------------------------------+        |
|  |                    |                     |                     |                 |
|  |                    v                     v                     v                 |
|  |  +--------------------------------+  +--------------------------------+        |
|  |  | Private Route Table (MyVPC-PrivateRT)                            |        |
|  |  | 0.0.0.0/0 -> NAT Gateway (MyVPC-NATGW)                          |        |
|  |  +----------------------------------------------------------------+        |
|  |                                                                            |
|  +-----------------------------------+-------------------------------+          |
|                                      |                               |          |
|                                      v                               v          |
|  +----------------------------+  +------------------------------------+         |
|  | Internet Gateway (MyVPC-IGW) |  | NAT Gateway (MyVPC-NATGW)        |         |
|  +----------------------------+  +------------------------------------+         |
|               |                               |                                |
|               v                               v                                |
|           [ Internet ]                 [ AWS Services (EKS, ECR, S3) ]        |
|                                                                            |
+----------------------------------------------------------------------------+
```

### Components and Their Roles

1. **VPC (MyVPC)**:
   - CIDR: `10.0.0.0/16`
   - Provides a logically isolated network environment.
   - DNS support and hostnames are enabled to support EKS cluster communication with AWS APIs.

2. **Public Subnets**:
   - CIDR blocks: `10.0.1.0/24` (us-east-1a), `10.0.2.0/24` (us-east-1b), `10.0.3.0/24` (us-east-1c), `10.0.4.0/24` (us-east-1d).
   - Named `PublicSubnet1` to `PublicSubnet4`.
   - Configured to assign public IPs on launch, suitable for resources like Application Load Balancers (ALBs) or NAT Gateways.
   - Associated with the public route table for direct internet access.

3. **Private Subnets**:
   - CIDR blocks: `10.0.11.0/24` (us-east-1a), `10.0.12.0/24` (us-east-1b), `10.0.13.0/24` (us-east-1c), `10.0.14.0/24` (us-east-1d).
   - Named `PrivateSubnet1` to `PrivateSubnet4`.
   - Designed to host EKS worker nodes, keeping them isolated from direct internet access.
   - Associated with the private route table, which routes outbound traffic through the NAT Gateway.

4. **Internet Gateway (MyVPC-IGW)**:
   - Enables public subnets to communicate with the internet.
   - Attached to the VPC and referenced in the public route table.

5. **NAT Gateway (MyVPC-NATGW)**:
   - Deployed in `PublicSubnet1` (us-east-1a) with an Elastic IP.
   - Allows private subnets to initiate outbound internet traffic (e.g., for pulling container images from Amazon ECR or accessing the EKS control plane).
   - Traffic from private subnets routes through the NAT Gateway to the Internet Gateway.

6. **Route Tables**:
   - **Public Route Table (MyVPC-PublicRT)**: Routes all traffic (`0.0.0.0/0`) to the Internet Gateway, enabling public subnets to access the internet directly.
   - **Private Route Table (MyVPC-PrivateRT)**: Routes all traffic (`0.0.0.0/0`) to the NAT Gateway, enabling private subnets to access the internet indirectly for outbound requests.

### Prerequisites

- **AWS CLI**: Installed and configured with credentials that have permissions to create VPCs, subnets, route tables, Internet Gateways, NAT Gateways, and Elastic IPs.
- **Region**: The script targets `us-east-1`. Modify the `REGION` variable if you need a different region.
- **Permissions**: Ensure your IAM role/user has permissions for `ec2:CreateVpc`, `ec2:CreateSubnet`, `ec2:CreateInternetGateway`, `ec2:CreateNatGateway`, `ec2:CreateRouteTable`, `ec2:CreateRoute`, `ec2:AssociateRouteTable`, `ec2:CreateTags`, `ec2:ModifyVpcAttribute`, `ec2:AttachInternetGateway`, `ec2:ModifySubnetAttribute`, `ec2:AllocateAddress`, and `ec2:DescribeNatGateways`.

### Usage

1. Save the script as `create-vpc.sh`.
2. Make it executable:
   ```bash
   chmod +x create-vpc.sh
   ```
3. Run the script:
   ```bash
   ./create-vpc.sh
   ```
4. The script will:
   - Create the VPC and tag it as `MyVPC`.
   - Enable DNS support and hostnames.
   - Create and attach an Internet Gateway (`MyVPC-IGW`).
   - Create four public and four private subnets across `us-east-1a` to `us-east-1d`.
   - Create a public route table (`MyVPC-PublicRT`) and associate it with public subnets.
   - Create a private route table (`MyVPC-PrivateRT`) and associate it with private subnets.
   - Deploy a NAT Gateway in `PublicSubnet1` and configure the private route table to route traffic through it.
   - Tag all resources with meaningful names.

### Outputs

The script outputs progress messages to the terminal, including the IDs of created resources (VPC, subnets, Internet Gateway, NAT Gateway, route tables). Example output:
```
Creating VPC...
VPC created with ID: vpc-1234567890abcdef0
Enabling DNS support and hostnames...
DNS support and hostnames enabled
Creating Internet Gateway...
Internet Gateway created with ID: igw-1234567890abcdef0
...
VPC setup complete!
```

### Considerations for EKS

- **Subnet Tags**: For EKS to recognize subnets, you may need to add tags like `kubernetes.io/cluster/<cluster-name>=shared` or `kubernetes.io/role/elb=1` (public subnets) and `kubernetes.io/role/internal-elb=1` (private subnets). Modify the script to include these tags in the subnet creation loops if you have a specific cluster name.
- **High Availability**: The script places the NAT Gateway in `us-east-1a`. For better resilience, consider deploying a NAT Gateway in each AZ (requires additional Elastic IPs and route tables, increasing costs).
- **VPC Endpoints**: To reduce NAT Gateway dependency, consider adding VPC endpoints for AWS services like ECR, S3, or CloudWatch. Example:
  ```bash
  aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.ecr.dkr \
    --route-table-ids $PRIVATE_RT_ID \
    --region us-east-1
  ```
- **Costs**: NAT Gateways and Elastic IPs incur charges. For cost optimization, evaluate VPC endpoints for private access to AWS services.
- **Security Groups**: The script doesn’t create security groups. For EKS, ensure worker nodes have security groups allowing communication with the EKS control plane and other necessary services.

### Cleanup

To delete the created resources (e.g., for testing), you must delete them in the correct order due to dependencies:
1. Delete the NAT Gateway and release the Elastic IP.
2. Delete subnets.
3. Delete route tables.
4. Detach and delete the Internet Gateway.
5. Delete the VPC.

Example cleanup commands:
```bash
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID --region us-east-1
aws ec2 release-address --allocation-id $EIP_ID --region us-east-1
aws ec2 delete-subnet --subnet-id $SUBNET_ID --region us-east-1
aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID --region us-east-1
aws ec2 delete-route-table --route-table-id $PRIVATE_RT_ID --region us-east-1
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region us-east-1
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region us-east-1
aws ec2 delete-vpc --vpc-id $VPC_ID --region us-east-1
```

### Troubleshooting

- **NAT Gateway Creation Fails**: Ensure the public subnet exists and has a route to the Internet Gateway.
- **EKS Communication Issues**: Verify DNS support and hostnames are enabled. Check that private subnets can reach the NAT Gateway.
- **Permission Errors**: Confirm your AWS CLI credentials have the required IAM permissions.
- **Subnet Tag Issues**: If EKS doesn’t recognize subnets, add the necessary `kubernetes.io` tags.

### Future Enhancements

- Add VPC endpoints for ECR, S3, and other services to reduce NAT Gateway usage.
- Support multiple NAT Gateways for high availability across AZs.
- Include security group creation for EKS worker nodes.
- Add error handling for resource creation failures (e.g., retry logic).

This setup provides a robust foundation for an EKS cluster, balancing security, scalability, and connectivity. For further customization, refer to the [AWS EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html).
