# using a shared key for both jenkins and nexus
resource "aws_key_pair" "gitops_key" {
  key_name   = "gitops-key"
  public_key = var.public_key # Pulled from your GitHub Secrets / tfvars
}

# passing the bastion key
resource "aws_key_pair" "bastion_pub_key" {
  key_name   = "bastion-gitops-key"
  public_key = var.bastion_pub_key
}

module "vpc" {
  source = "../../modules/vpc"
}

module "bastion" {
  source = "../../modules/bastion"
  # bastion_pub_key = var.bastion_pub_key # bastion has its own key defined in its module
  bastion_key_name    = aws_key_pair.bastion_pub_key.key_name
  bastion_sg_id       = module.security.bastion_sg
  pub_sub             = module.vpc.pub_sub
  bastion_eks_profile = module.iam.bastion_eks_profile
}

module "sonaqube" {
  source = "../../modules/sonarqube"
  key_name = aws_key_pair.gitops_key.key_name
  pvt_sub = module.vpc.pvt_sub
  sonarqube_sg = module.security.sonarqube_sg
}

module "jenkins" {
  source        = "../../modules/jenkins"
  jenkins_sg_id = module.security.jenkins_sg
  pvt_sub       = module.vpc.pvt_sub
  key_name      = aws_key_pair.gitops_key.key_name #passing the key name of shared key
}

module "nexus" {
  source      = "../../modules/nexus"
  pvt_sub     = module.vpc.pvt_sub
  nexus_sg_id = module.security.nexus_sg
  key_name    = aws_key_pair.gitops_key.key_name
}

module "iam" {
  source = "../../modules/iam"
}

module "eks" {
  source                  = "../../modules/eks"
  eks_cluster_role_arn    = module.iam.eks_cluster_role_arn
  pvt_sub                 = module.vpc.pvt_sub
  pvt_sub_2               = module.vpc.pvt_sub_2
  eks_node_group_role_arn = module.iam.eks_node_group_role_arn
  bastion_eks_role_arn = module.iam.bastion_eks_profile_arn
}

# 2. passes the fetched IP down into the security module block.
module "security" {
  source = "../../modules/security"

  # catches that output vpc_ID and hands it to the security module block
  vpc_id = module.vpc.vpc_id

  # This takes the root var.my_ip (from GitHub) 
  # and hands it to the security module's var.my_ip
  my_ip = var.my_ip
}