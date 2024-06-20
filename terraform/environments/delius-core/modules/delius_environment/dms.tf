module "dms" {
  source                      = "../components/dms"
  account_config              = var.account_config
  account_info                = var.account_info
  tags                        = var.tags
  env_name                    = var.env_name
  platform_vars               = var.platform_vars

  delius_core_application_passwords_arn = module.oracle_db_shared.delius_core_application_passwords_arn
  oracle_db_server_names                = local.oracle_db_server_names

  dms_config = lookup(local.dms_config, terraform.workspace, {
    replication_instance_class = "dms.t3.small"
    engine_version             = "3.5.1"
  })
  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws
    aws.core-network-services = aws
  }
}

locals {
  dms_config = {
    "delius-core-development" = {
      replication_instance_class = "dms.t3.small"
      engine_version             = "3.5.1"
    }
    "delius-core-test" = {
      replication_instance_class = "dms.t3.medium"
      engine_version             = "3.5.1"
    }
  }

  oracle_db_server_names = {
     primarydb = module.oracle_db_primary[0].oracle_db_server_name,
     standbydb1 = try(module.oracle_db_standby[0].oracle_db_server_name,"none"),
     standbydb2 = try(module.oracle_db_standby[1].oracle_db_server_name,"none")
  }

}