output "bucket_name" {
  value = aws_s3_bucket.cloudtrail_log_bucket.bucket
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.trail.arn
}
