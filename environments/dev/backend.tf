terraform {
  backend "s3" {
    bucket = "backend-buck-tf"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-locks"
    # depricated so we will use s3 object locking instead of dynamodb for state locking
    use_lockfile = true
    encrypt      = true
  }
}