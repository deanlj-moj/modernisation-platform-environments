resource "aws_kms_key" "athena_workspace_result_encryption_key" {
  description         = "KMS key for encrypting the ${aws_athena_workgroup.default.name} Athena Workspace's results"
  enable_key_rotation = true

  policy = jsonencode(
    {
      "Id": "key-default",
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::${local.env_account_id}:root"
          },
          "Action": "kms:*",
          "Resource": "*"
        },
        {
          "Sid": "Enable log service Permissions",
          "Effect": "Allow",
          "Principal": {
            "Service": "logs.eu-west-2.amazonaws.com"
          },
          "Action": [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
          ],
          "Resource": "*"
        }
      ]
    }
  )
  tags = merge(
    local.tags,
    {
      Resource_Type = "KMS key for query result encryption used with ${aws_athena_workgroup.default.name} Athena Workgroup",
    }
  )
}

resource "aws_athena_workgroup" "default" {
  name = "default"
  description = "A default Athena workgroup to set query limits and link to the default query location bucket: ${module.athena-s3-bucket.name}"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    engine_version {
        selected_engine_version = "AUTO"
    }

    result_configuration {
      output_location = "s3://${module.athena-s3-bucket.bucket}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.athena_workspace_result_encryption_key.arn
      }
    }

    bytes_scanned_cutoff_per_query = 107374182400 # 100 GB
  }
  tags = merge(
    local.tags,
    {
      Resource_Type = "Athena Workgroup for default Query Result Location results, logs and query limits",
    }
  )
}
