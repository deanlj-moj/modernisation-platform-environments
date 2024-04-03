module "quarantined_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.0.1"

  name              = "quarantined"
  display_name      = "quarantined"
  signature_version = 2

  kms_master_key_id = module.quarantined_sns_kms.key_id

  topic_policy_statements = {
    AllowQuarantineS3 = {
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [module.quarantine_bucket.s3_bucket_arn]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  }

  subscriptions = {
    s3 = {
      protocol = "lambda"
      endpoint = module.transfer_lambda.lambda_function_arn # to be corrected
    }
  }
}

module "transferred_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.0.1"

  name              = "transferred"
  display_name      = "transferred"
  signature_version = 2

  kms_master_key_id = module.transferred_sns_kms.key_id

  subscriptions = {
    lambda = {
      protocol = "lambda"
      endpoint = module.transfer_lambda.lambda_function_arn
    }
  }
}
