variable "jenkins_sg_id"{
    type = string
    description = "Id of the jenkins SG"
}

variable "pvt_sub" {
  type = string
  description = "ID of the private subnet"
}

variable "public_key" {
    type = string
    description = ".pub key for ssh access to jenkins"
}