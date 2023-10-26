resource "aws_s3_bucket" "tag-secured-bucket" {
  bucket_prefix = local.application_name
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_object" "tag-secured-object" {
  for_each = nonsensitive(local.environment_management.account_ids)
  bucket   = aws_s3_bucket.tag-secured-bucket.id
  key      = each.key
  source   = "./application_variables.json"
  tags = merge(
    local.tags,
    { "PermittedAccount" = each.value }
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
    resources = [format("%s/*", aws_s3_bucket.tag-secured-bucket.arn)]
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
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/PermittedAccount"
      values   = ["&{aws:PrincipalAccount}"]
    }
  }
}