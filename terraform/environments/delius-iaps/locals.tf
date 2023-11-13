#### This file can be used to store locals specific to the member account ####
locals {
  ndelius_interface_params      = yamldecode(file("${path.module}/files/ndelius_interface_ssm_params.yml"))
  iaps_snapshot_data_refresh_id = local.application_data.accounts[local.environment].db_snapshot_identifier
}
