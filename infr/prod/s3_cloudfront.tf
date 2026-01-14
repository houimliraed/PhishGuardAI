# S3 bucket for frontend assets

resource "aws_s3_bucket" "frontend" {
  bucket = "${local.prefix}-frontend-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${local.prefix}-frontend-bucket"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# Block public access to S3 bucket (CloudFront will access it)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${local.prefix} frontend"

  lifecycle {
    ignore_changes = [comment]
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2and3"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-frontend"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior for API calls
  ordered_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    path_pattern     = "/api/*"
    target_origin_id = "s3-frontend"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }

      headers = ["*"]
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # Error handling
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${local.prefix}-frontend-distribution"
  }
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${local.prefix}-frontend-oac"
  description                       = "OAC for ${local.prefix} frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  lifecycle {
    ignore_changes = [description]
  }
}

# Route53 DNS record (optional - if you have a domain)
resource "aws_route53_record" "frontend" {
  count   = var.frontend_domain_name != "" && var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.frontend_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Outputs
output "s3_bucket_name" {
  value       = aws_s3_bucket.frontend.id
  description = "S3 bucket name for frontend assets"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.frontend.domain_name
  description = "CloudFront distribution domain name"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "CloudFront distribution ID"
}

output "cloudfront_distribution_arn" {
  value       = aws_cloudfront_distribution.frontend.arn
  description = "CloudFront distribution ARN"
}

output "frontend_url" {
  value       = var.frontend_domain_name != "" ? "https://${var.frontend_domain_name}" : "https://${aws_cloudfront_distribution.frontend.domain_name}"
  description = "Frontend URL"
}
