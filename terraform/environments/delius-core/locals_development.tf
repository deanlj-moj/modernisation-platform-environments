# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  development_config_baseline = {
    ec2_instances = {
      tags        = local.tags
      description = "set at the account level"
    }
  }

  development_config = {
    ec2_instances = {
      db-1-dev = {
        environment = "dev1"
        name        = "dbprimary" # Specific, resource-level value
        description = try(local.development_config_baseline.ec2_instances.description, "")
        tags = {
          "HA status" = "primary"
        }
      },
      db-2-dev = {
        environment = "dev1"
        name        = "dbsecondary"
        description = try(local.development_config_baseline.ec2_instances.description, "")
        tags = {
          "HA status" = "secondary"
        }
      },
      db-1-dev2 = {
        environment = "dev2"
        name        = "dbprimary"
        description = try(local.development_config_baseline.dev2.ec2_instances.description, "")
      },
      db-2-dev2 = {
        environment = "dev2"
        name        = "dbsecondary"
        description = try(local.development_config_baseline.dev2.ec2_instances.description, "")
      }
    }
  }
}
