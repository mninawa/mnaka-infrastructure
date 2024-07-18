variable "ENV" {
    default = "mnaka-dev"
}

variable "REGION" {
  default = "af-south-1"
}

variable "VPC" {
  type = object({
    CIDR = string
    SUBNET_PRIVATE = list(string)
    SUBNET_PUBLIC = list(string)
    SUBNET_DB = list(string)
  })
  default = {
    "CIDR" = "10.30.0.0/16",
    "SUBNET_DB" = ["10.30.1.0/24", "10.30.2.0/24"],
    "SUBNET_PRIVATE" = ["10.30.3.0/24", "10.30.4.0/24"],
    "SUBNET_PUBLIC" = ["10.30.5.0/24", "10.30.6.0/24"]
  }
}

variable "SUPPORT_EMAILS" {
  type    = list(string)
  default = []
}