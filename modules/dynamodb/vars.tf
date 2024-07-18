variable "ENV" {}
variable "RESOURCE_PREFIX" {}
variable "COMMON_TAGS"{}


variable "BILLING_MODE" {
  default = "PAY_PER_REQUEST"
}

variable "CREATE_SORT_KEY" {
  default = false
}

variable "SORT_KEY_NAME" {
  default = "sort_key"
}