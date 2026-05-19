# EKS CLUSTER ROLE

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"
  # Defininf a assume role policy which would let only the allowed services to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com" # which service can assume this role
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" # Direct atatch using ARN as im using a default policy
}


# EKS NODE GROUP ROLE

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks_node_group_role"
  # Defininf a assume role policy which would let only the allowed services to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com" # which service can assume this role, EC2 here will be our nodes in the cluster
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_group_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" # Direct atatch using ARN as im using a default policy
}

resource "aws_iam_role_policy_attachment" "eks_cni_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" # Direct atatch using ARN as im using a default policy
}

resource "aws_iam_role_policy_attachment" "ECR_read_only_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Direct atatch using ARN as im using a default policy
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}
output "eks_node_group_role_arn" {
  value = aws_iam_role.eks_node_group_role.arn
}