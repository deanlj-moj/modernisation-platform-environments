output "arn" {
    description = "ARN of the lambda"
    value = module.data_product_authorizer_lambda.lambda_function_arn
}

output "invoke_arn" {
    description = "Invoke ARN of the lambda"
    value = module.data_product_authorizer_lambda.lambda_function_invoke_arn
}