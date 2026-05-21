resource "aws_eks_cluster" "gitops_cluster" {
  name = "gitops_cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.eks_cluster_role_arn
  version  = "1.34"

  vpc_config {
    subnet_ids = [var.pvt_sub, var.pvt_sub_2]
  }
}

# Map the Bastion role directly to an EKS Access Entry
resource "aws_eks_access_entry" "bastion_eks_access" {
  cluster_name  = aws_eks_cluster.gitops_cluster.name
  principal_arn = var.bastion_eks_role_arn
  type          = "STANDARD"
}

# Associate the ClusterAdminPolicy to that specific Access Entry
resource "aws_eks_access_policy_association" "bastion_admin_bind" {
  cluster_name  = aws_eks_cluster.gitops_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.bastion_eks_access.principal_arn

  access_scope {
    type = "cluster"
  }
}