# receives the value and feeds it into your security.tf
variable "my_ip" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "The ID of the target VPC"
}