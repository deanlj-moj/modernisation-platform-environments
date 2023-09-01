module "data_product_authorizer_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v2.0.1"
  application_name               = "data_product_authorizer"
  tags                           = var.tags
  description                    = "Lambda for custom API Gateway authorizer"
  role_name                      = "authorizer_lambda_role_${var.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_authorizer_lambda.json
  function_name                  = "data_product_authorizer_${var.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-authorizer-lambda-ecr-repo:${var.authorizer_version}"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  environment_variables = {
    authorizationToken = "placeholder"
    api_resource_arn   = var.api_resource_arn
  }

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action        = "lambda:InvokeFunction"
      function_name = "data_product_authorizer_${var.environment}"
      principal     = "apigateway.amazonaws.com"
      source_arn    = var.api_source_arn
    }
  }
}

data "aws_iam_policy_document" "iam_policy_document_for_authorizer_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/*"]
  }
}
