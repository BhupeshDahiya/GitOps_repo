module "vpc" {
  source = "../../modules/vpc"
}

module "bastion" {
  source = "../../modules/bastion"
  # public_subnet = module.vpc.public_subnet_1_id 
}

module "jenkins" {
  source = "../../modules/jenkins"
  jenkins_sg_id = module.security.jenkins_sg
  pub_sub = module.vpc.pub_sub
  public_key = module.jenkins.public_key
}

module "nexus" {
  source = "../../modules/nexus"
  # private_subnet = module.vpc.private_subnet_2_id 
}

module "eks" {
  source = "../../modules/eks"
  # private_subnets = module.vpc.private_subnets 
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