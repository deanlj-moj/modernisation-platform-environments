module "oracle_observer" {
  source                = "../helpers/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  certificate_arn       = aws_acm_certificate.external.arn

  # Do not create an Oracle Observer microservice if it has no configuration
  desired_count = try(var.delius_microservice_configs.oracle_observer,{}) == {} ? 0 : 1

  container_secrets_env_specific = {}

  container_port_config = []

  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  env_name        = var.env_name

  target_group_protocol_version = "HTTP1"

  name                       = "oracle-observer"
  container_image            = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-oracle-observer:${var.delius_microservice_configs.oracle_observer.image_tag}"
  platform_vars              = var.platform_vars
  tags                       = var.tags
  db_ingress_security_groups = []

  container_cpu                      = var.delius_microservice_configs.oracle_observer.container_cpu
  container_memory                   = var.delius_microservice_configs.oracle_observer.container_memory
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  ecs_service_ingress_security_group_ids = []
  ecs_service_egress_security_group_ids = [
    {
      ip_protocol = "tcp"
      port        = var.db_config.database_port
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    }
  ]

  cluster_security_group_id = aws_security_group.cluster.id

  ignore_changes_service_task_definition = false

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern      = "FATAL"
  sns_topic_arn          = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix = aws_lb.delius_core_frontend.arn_suffix

  bastion_sg_id = module.bastion_linux.bastion_security_group

  container_vars_default = {}

  container_vars_env_specific = {
    "PRIMARYDB_HOSTNAME"  = join(".",[local.oracle_db_server_names["primarydb"], var.account_config.route53_inner_zone.name])
    "STANDBYDB1_HOSTNAME" = local.oracle_db_server_names["standbydb1"] == "none" ? "none" : join(".",[local.oracle_db_server_names["standbydb1"], var.account_config.route53_inner_zone.name])
    "STANDBYDB2_HOSTNAME" = local.oracle_db_server_names["standbydb2"] == "none" ? "none" : join(".",[local.oracle_db_server_names["standbydb2"], var.account_config.route53_inner_zone.name])
    "DATABASE_PORT"       = var.db_config.database_port
    "DATABASE_NAME"       = var.db_config.database_name
    "DUMMY_VALUE"         = "force_redeploy"
    }

  container_secrets_default = {
    "DATABASE_SECRETS_JSON" = "arn:aws:secretsmanager:eu-west-2:${var.account_info.id}:secret:${var.app_name}-${var.env_name}-oracle-db-dba-passwords"
  }
}
