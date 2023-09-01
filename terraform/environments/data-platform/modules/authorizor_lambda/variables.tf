// Possible variables:
// tags
// environment
// region
// account id
// api resource ARN (aws_api_gateway_rest_api.data_platform.execution_arn)
// source ARN ("arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/*")

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "api_resource_arn" {
  description = "The resource ARN of the API gateway"
  type        = string
}

variable "api_source_arn" {
  description = "The source ARN of the API gateway"
  type        = string
}

variable "authorizer_version" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}