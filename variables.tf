variable "environment" {
  description = "Environment"
  default     = "staging"
}

variable "aws_region" {
  type = string
  default = "ap-east-1"
}

// VPC
variable "vpc_name" {
  type = string
  description = "VPC Name"
}

variable "vpc_cidr" {
  type = string
  description = "VPC CIDR block"
}
