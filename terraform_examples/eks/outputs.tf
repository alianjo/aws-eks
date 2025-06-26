# outputs.tf

# Output the EKS cluster endpoint
output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

# Output the EKS cluster name
output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.name
}

# Output the EKS cluster CA certificate data
output "eks_cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with your cluster."
  value       = aws_eks_cluster.eks_cluster.certificate_authority.0.data
}

# Output the ARN of the EKS cluster role
output "eks_cluster_role_arn" {
  description = "The ARN of the IAM role for the EKS cluster."
  value       = aws_iam_role.eks_cluster_role.arn
}

# Output the ARN of the EKS node group role
output "eks_node_group_role_arn" {
  description = "The ARN of the IAM role for the EKS node group."
  value       = aws_iam_role.eks_node_group_role.arn
}

# Output public subnet IDs
output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public_subnets[*].id
}

# Output private subnet IDs
output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private_subnets[*].id
}

# Instructions for configuring kubectl
output "kubectl_config_instructions" {
  description = "Instructions to configure kubectl to connect to your EKS cluster."
  value = "To connect to your cluster, run: aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks_cluster.name}"
}
