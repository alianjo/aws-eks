# --- EKS Cluster Setup ---

data "aws_partition" "current" {}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids             = flatten([aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id])
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  depends_on = [
    aws_route_table_association.public_route_table_associations,
    aws_route_table_association.private_route_table_associations,
    aws_route_table_association.private_route_table_associations_2,
  ]

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]

  tags = {
    Name = "${var.cluster_name}-node-group"
  }
} 