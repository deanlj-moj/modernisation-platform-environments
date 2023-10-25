resource "aws_s3_bucket" "tag-secured-bucket"{
  bucket_prefix = local.application_name
  force_destroy = true
  tags = merge(
    local.tags,
    { "PermittedAccounts" = format("%s, %s", local.environment_management.account_ids["sprinkler-development"], local.environment_management.account_ids["cooker-development"]) }
  )
}

resource "aws_s3_object" "tag-secured-object" {
  bucket = aws_s3_bucket.tag-secured-bucket.id
  key    = "testobject"
  source = "./application_variables.json"
  tags   = merge(
    local.tags,
    { "PermittedAccounts" = format("%s, %s", local.environment_management.account_ids["sprinkler-development"], local.environment_management.account_ids["cooker-development"]) }
  )
}

resource "aws_s3_bucket_policy" "tag-secured-bucket" {
  bucket = aws_s3_bucket.tag-secured-bucket.id
  policy = data.aws_iam_policy_document.tag-secured-bucket.json
}

data "aws_iam_policy_document" "tag-secured-bucket" {

  statement {
    sid       = "ListBucket"
    actions   = ["s3:List*"]
    resources = [aws_s3_bucket.tag-secured-bucket.arn]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = ["${data.aws_organizations_organization.root_account.id}/*/${local.environment_management.modernisation_platform_organisation_unit_id}/*"]
    }
  }

  statement {
    sid       = "SecureObjectWithTag"
    actions   = ["s3:Get*", "s3:Put*"]
    resources = [format("%s/%s", aws_s3_bucket.tag-secured-bucket.arn, aws_s3_object.tag-secured-object.key)]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:PrincipalOrgPaths"
      values   = ["${data.aws_organizations_organization.root_account.id}/*/${local.environment_management.modernisation_platform_organisation_unit_id}/*"]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:SourceAccount"
      values   = ["s3:ExistingObjectTag/PermittedAccounts"]
    }
  }
}