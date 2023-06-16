module "account_all_components" {
  source = "./modules/account_all_components"

  ec2_instances           = lookup(local.account_config, "ec2_instances", {})
  account_config_baseline = local.account_config_baseline

  account = {
    vpc_id = data.aws_vpc.shared.id
  }
}



# module "ldap" {
#   count = if()
#   source = "./modules/account"

#   ec2_instances = lookup(local.environment_config, "ec2_instances", {})

#   account = {
#     vpc_id = data.aws_vpc.shared.id
#   }
# }

