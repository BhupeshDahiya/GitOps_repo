resource "aws_key_pair" "bastion_pub_key" {
  key_name   = "bastion-gitops-key"
  public_key = var.bastion_pub_key
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.bastion_pub_key.key_name # Hooks the key to the instance
  vpc_security_group_ids = [var.bastion_sg_id]
  # availability_zone      = "us-east-1a"
  subnet_id = var.pub_sub
  root_block_device {
    volume_size           = 8     
    volume_type           = "gp3"  
    encrypted             = true   # Enforce data-at-rest encryption
    delete_on_termination = true   # Clean up the disk automatically if the instance is destroyed

    tags = {
      Name = "bastion_root_volume"
    }
  }
  tags = {
    Name = "gitops_bastion"
  }

}
