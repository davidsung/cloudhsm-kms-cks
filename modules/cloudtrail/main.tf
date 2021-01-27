resource "random_id" "cloudtrail_log_bucket_suffix" {
  byte_length = 3

  keepers = {
    bucket_name = var.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_log_bucket_bpa" {
  bucket                  = aws_s3_bucket.cloudtrail_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_log_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_log_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_log_bucket.json
}

resource "aws_s3_bucket" "cloudtrail_log_bucket" {
  bucket = format("%s-%s", var.bucket_name, random_id.cloudtrail_log_bucket_suffix.hex)

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  force_destroy = true

  tags = var.tags
}

resource "aws_cloudtrail" "trail" {
  name                          = "cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_log_bucket.id
  s3_key_prefix                 = var.bucket_key_prefix
  include_global_service_events = true
  is_multi_region_trail         = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_log_bucket_policy]
  tags                          = var.tags
}

data "aws_iam_policy_document" "cloudtrail_log_bucket" {
  statement {
    sid = "AWSCloudTrailAclCheck"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "arn:aws:s3:::${format("%s-%s", var.bucket_name, random_id.cloudtrail_log_bucket_suffix.hex)}"
    ]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${format("%s-%s", var.bucket_name, random_id.cloudtrail_log_bucket_suffix.hex)}/${var.bucket_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}
