variable "bucket_name" {
  type = string
  description = "Bucket name for storing CloudTrail Log"
}

variable "bucket_key_prefix" {
  type = string
  description = "Prefix in S3 bucket"
  default = "cloudtrail"
}

variable "tags" {
  type = map(string)
  description = "A map of tags to add to all resources"
  default = {}
}
