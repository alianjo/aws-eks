# variables.tf

# AWS region to deploy resources
variable "aws_region" {
  description = "The AWS region where the EKS cluster will be deployed."
  type        = string
  default     = "us-east-1"
}

# Name of the EKS cluster
variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "my-cost-effective-eks"
}

# VPC CIDR block
variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# Kubernetes version for the EKS cluster
variable "kubernetes_version" {
  description = "The Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.28" # Use a recent, stable version
}

# EC2 instance type for EKS worker nodes
variable "instance_type" {
  description = "The EC2 instance type for the EKS worker nodes."
  type        = string
  default     = "t3.medium" # Cost-effective option
}

# Desired number of worker nodes
variable "desired_node_count" {
  description = "The desired number of worker nodes for the EKS cluster."
  type        = number
  default     = 2 # Minimal nodes for cost efficiency
}

# Maximum number of worker nodes
variable "max_node_count" {
  description = "The maximum number of worker nodes for the EKS cluster."
  type        = number
  default     = 3 # Allows for some scaling
}

# Minimum number of worker nodes
variable "min_node_count" {
  description = "The minimum number of worker nodes for the EKS cluster."
  type        = number
  default     = 2 # Ensures minimum availability
}
