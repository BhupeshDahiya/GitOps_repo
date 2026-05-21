resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.bastion_key_name # Hooks the key to the instance
  vpc_security_group_ids = [var.bastion_sg_id]
  # availability_zone      = "us-east-1a"
  subnet_id            = var.pub_sub
  iam_instance_profile = var.bastion_eks_profile

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true # Enforce data-at-rest encryption
    delete_on_termination = true # Clean up the disk automatically if the instance is destroyed
    tags = {
      Name = "bastion_root_volume"
    }
  }

  tags = {
    Name = "gitops_bastion"
  }

}
