# 2. passes the fetched IP down into the security module block.
module "security" {
  source = "../../modules/security"
  
  # catches that output vpc_ID and hands it to the security module block
  vpc_id = module.vpc.vpc_id
   
  # This takes the root var.my_ip (from GitHub) 
  # and hands it to the security module's var.my_ip
  my_ip  = var.my_ip 
}