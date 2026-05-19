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
