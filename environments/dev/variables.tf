# 1. Fetches the ip variable set in github secrets variable
variable "my_ip" {
  type = string
}

variable "public_key" {
  type = string
}

variable "bastion_pub_key" {
  type = string
}