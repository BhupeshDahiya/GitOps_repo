resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = var.key_name # Hooks the key to the instance
  vpc_security_group_ids = [var.jenkins_sg_id]
  # availability_zone      = "us-east-1a"
  subnet_id = var.pvt_sub
  user_data              = file("${path.module}/../../modules/jenkins/jenkins.sh") # path to the script to be run for instance
  root_block_device {
    volume_size           = 12     
    volume_type           = "gp3"  
    encrypted             = true   # Enforce data-at-rest encryption
    delete_on_termination = true   # Clean up the disk automatically if the instance is destroyed

    tags = {
      Name = "jenkins_root_volume"
    }
  }
  tags = {
    Name = "gitops_jenkins"
  }

}