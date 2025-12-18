# -------------------------
# EKS Managed Node Group
# -------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  instance_types = var.instance_types
  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2_x86_64"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
