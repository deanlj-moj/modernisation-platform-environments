# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ec2_instances = {
      t3-csr-db-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          ami_owner         = "self"
          availability_zone = "${local.region}a"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type                = "r6i.xlarge"
          disable_api_termination      = true
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
          monitoring                   = true
          vpc_security_group_ids       = ["data-db"]
        })

      user_data_cloud_init = {
        args = {
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "--tags ec2provision"
        }
        scripts = [
          "ansible-ec2provision.sh.tftpl",
        ]
    }

    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", label = "app", size = 100 } # /u01
      "/dev/sdc" = { type = "gp3", label = "app", size = 100 } # /u02
      "/dev/sde" = { type = "gp3", label = "data" }            # DATA01
      "/dev/sdf" = { type = "gp3", label = "data" }            # DATA02
      "/dev/sdg" = { type = "gp3", label = "data" }            # DATA03
      "/dev/sdh" = { type = "gp3", label = "data" }            # DATA04
      "/dev/sdi" = { type = "gp3", label = "data" }            # DATA05
      "/dev/sdj" = { type = "gp3", label = "flash" }           # FLASH01
      "/dev/sdk" = { type = "gp3", label = "flash" }           # FLASH02
      "/dev/sds" = { type = "gp3", label = "swap" }
    }

    ebs_volume_config = {
      data = {
        iops       = 3000
        throughput = 125
        total_size = 500
      }
      flash = {
        iops       = 3000
        throughput = 125
        total_size = 50
      }
    }

    route53_records = {
      create_internal_record = true
      create_external_record = true
    }

    ssm_parameters = {
      ASMSYS = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSYS password"
      }
      ASMSNMP = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSNMP password"
      }
    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = ["private-lb"]

        listeners = {
          http = local.weblogic_lb_listeners.http

          http7777 = merge(local.weblogic_lb_listeners.http7777, {
            rules = {
              # T1 users in Azure accessed server directly on http 7777
              # so support this in Mod Platform as well to minimise
              # disruption.  This isn't needed for other environments.
              t1-nomis-web-a = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.az.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                      "t1-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-nomis-web-b = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })

          https = merge(local.weblogic_lb_listeners.https, {
            alarm_target_group_names = ["t1-nomis-web-a-http-7777"]
            rules = {
              t1-nomis-web-a-http-7777 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.az.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                      "t1-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-nomis-web-b-http-7777 = {
                priority = 450
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-a-http-7777 = {
                priority = 550
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t2-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t2.test.nomis.az.justice.gov.uk",
                      "c-t2.test.nomis.service.justice.gov.uk",
                      "t2-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-b-http-7777 = {
                priority = 600
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t2-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-a-http-7777 = {
                priority = 700
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t3-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t3.test.nomis.az.justice.gov.uk",
                      "c-t3.test.nomis.service.justice.gov.uk",
                      "t3-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-b-http-7777 = {
                priority = 800
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t3-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        }
      }
    }

    tags = {
      description = "Test CSR DB server"
      ami         = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
      os-type     = "Linux"
      component   = "test"
      server-type = "csr-db"
    }
      }
    }
      baseline_route53_zones = {
        "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
          records = [
            { name = "t3-csr-db-a", type = "CNAME", ttl = "300", records = ["t3-csr-db-a.corporate-staff-rostering.hmpps-test.modernisation-platform.service.justice.gov.uk"] }
          ]
        }
    }


    baseline_s3_buckets = {
      # use this bucket for storing artefacts for use across all accounts
      csr-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

  }
}
