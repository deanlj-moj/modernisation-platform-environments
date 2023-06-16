##
# Terraform to deploy an instance to test out a base Oracle AMI
##

# Pre-req - security group
resource "aws_security_group" "db_sg" {
  for_each = var.ec2_instances

  name        = format("%s-db-sg", each.key)
  description = each.value.description
  vpc_id      = var.account.vpc_id
  tags = merge(
    var.account_config_baseline.ec2_instances.tags,
    each.value.tags
  )
}

