variable "jenkins_sg_id"{
    type = string
    description = "Id of the jenkins SG"
}

variable "pub_sub" {
  type = string
  description = "ID of the public subnet"
}

variable "public_key" {
    type = string
    description = ".pub key for ssh access to jenkins"
}