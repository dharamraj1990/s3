output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the bucket"
  value       = aws_s3_bucket.main.hosted_zone_id
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.versioning_enabled
}

output "encryption_enabled" {
  description = "Whether encryption is enabled"
  value       = var.encryption_enabled
}

output "encryption_type" {
  description = "Type of encryption used"
  value       = var.encryption_type
}

output "kms_key_id" {
  description = "KMS key ID used for encryption (if applicable)"
  value       = var.kms_key_id
  sensitive   = true
}

output "public_access_block" {
  description = "Public access block configuration"
  value = {
    block_public_acls       = var.block_public_acls
    block_public_policy     = var.block_public_policy
    ignore_public_acls      = var.ignore_public_acls
    restrict_public_buckets = var.restrict_public_buckets
  }
}

output "secure_transport_enabled" {
  description = "Whether secure transport (HTTPS only) is enabled"
  value       = var.enable_secure_transport
}

output "lifecycle_policy_enabled" {
  description = "Whether lifecycle policy is enabled"
  value       = var.enable_lifecycle_policy
}

output "bucket_type" {
  description = "Type of bucket"
  value       = var.bucket_type
}

