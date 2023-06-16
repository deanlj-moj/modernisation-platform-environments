variable "ec2_instances" {
  type = map(object({
    environment = string
    name        = string
    description = string
    tags        = optional(map(string))
  }))
}

variable "account_config_baseline" {
  type = any
}

variable "account" {
  type = map(any)
}
