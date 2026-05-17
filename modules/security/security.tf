##  Bastion SG

resource "aws_security_group" "bastion_sg" {
  name        = "Allow SSH"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "Bastion_SSH"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "TCP"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_from_bastion" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


##  Jenkins SG


resource "aws_security_group" "jenkins_sg" {
  name        = "Jenkins_SG"
  description = "Allow inbound from bastion and full outbound traffic" #Allow full outbound traffic (required to pull Git repositories, download Jenkins plugins, and hit AWS/EKS APIs).
  vpc_id      = var.vpc_id

  tags = {
    Name = "gitops_jenkins"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_bastion_into_jenkins" {
  security_group_id = aws_security_group.jenkins_sg.id
  referenced_security_group_id   = aws_security_group.bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_from_bastion_into_jenkins" {
  security_group_id = aws_security_group.jenkins_sg.id
  referenced_security_group_id   = aws_security_group.bastion_sg.id
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_jenkins" {
  security_group_id = aws_security_group.jenkins_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


## Nexus SG


resource "aws_security_group" "nexus_sg" {
  name        = "Nexus_SG"
  description = "Allow inbound from bastion and jenkins and full outbound traffic" 
  vpc_id      = var.vpc_id

  tags = {
    Name = "gitops_nexus"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_bastion_into_nexus" {
  security_group_id = aws_security_group.nexus_sg.id
  referenced_security_group_id   = aws_security_group.bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_from_bastion_into_nexus" {
  security_group_id = aws_security_group.nexus_sg.id
  referenced_security_group_id   = aws_security_group.bastion_sg.id
  from_port         = 8081
  ip_protocol       = "tcp"
  to_port           = 8081
}

resource "aws_vpc_security_group_ingress_rule" "allow_jenkins_to_push_artifact_to_nexus" {
  security_group_id = aws_security_group.nexus_sg.id
  referenced_security_group_id   = aws_security_group.jenkins_sg.id
  from_port         = 8081
  ip_protocol       = "tcp"
  to_port           = 8081
}

resource "aws_vpc_security_group_ingress_rule" "allow_eks_to_pull_images" {
  security_group_id = aws_security_group.nexus_sg.id
  referenced_security_group_id   = aws_security_group.eks_sg.id
  from_port         = 8081
  ip_protocol       = "tcp"
  to_port           = 8081
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_from_nexus" {
  security_group_id = aws_security_group.nexus_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


## EKS SG


resource "aws_security_group" "eks_sg" {
  name        = "EKS_SG"
  description = "Allow internal traffic and inbound from bastion and jenkins and full outbound traffic" 
  vpc_id      = var.vpc_id

  tags = {
    Name = "gitops_eks"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_bastion_into_eks" {
  security_group_id = aws_security_group.eks_sg.id
  referenced_security_group_id   = aws_security_group.bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_internal_communication" {
  security_group_id = aws_security_group.eks_sg.id
  referenced_security_group_id   = aws_security_group.eks_sg.id
  # from_port         = 0
  ip_protocol       = "-1" # all ports
  # to_port           = 0
  # no need to define form and to ports if using ip_protocol as -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_jenkins_into_eks" {
  security_group_id = aws_security_group.eks_sg.id
  referenced_security_group_id   = aws_security_group.jenkins_sg.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_from_eks" {
  security_group_id = aws_security_group.eks_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
