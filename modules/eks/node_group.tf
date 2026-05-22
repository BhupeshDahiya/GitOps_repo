resource "aws_eks_node_group" "gitops_node_group" {
  cluster_name    = aws_eks_cluster.gitops_cluster.name
  node_group_name = "gitops_node_group"
  node_role_arn   = var.eks_node_group_role_arn
  subnet_ids      = [var.pvt_sub, var.pvt_sub_2]
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}