module "cloudtrail" {
  source = "./modules/cloudtrail"

  bucket_name = "cloudtrail"

  tags = {
    Environment = var.environment
  }
}
