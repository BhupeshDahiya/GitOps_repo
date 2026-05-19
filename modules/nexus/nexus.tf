resource "aws_instance" "nexus" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"  # nexus needs 4gb ram to run
  key_name               = var.key_name # Hooks the key to the instance
  vpc_security_group_ids = [var.nexus_sg_id]
  # availability_zone      = "us-east-1a"
  subnet_id = var.pvt_sub
  user_data = file("${path.module}/../../modules/nexus/nexus.sh") # path to the script to be run for instance
  root_block_device {
    volume_size           = 12
    volume_type           = "gp3"
    encrypted             = true # Enforce data-at-rest encryption
    delete_on_termination = true # Clean up the disk automatically if the instance is destroyed

    tags = {
      Name = "nexus_root_volume"
    }
  }
  tags = {
    Name = "gitops_nexus"
  }

}