# Example configurations for S3 Bucket Module

# ============================================
# Example 1: Normal Bucket with Default Settings
# ============================================
# This creates a secure bucket with:
# - SSE-S3 encryption
# - Public access blocked
# - Secure transport (HTTPS only)
# - Default lifecycle policies
# - Versioning enabled

# inputs = {
#   bucket_name = "myapp-data-bucket"
#   bucket_type = "normal"
#   environment = "dev"
# }

# ============================================
# Example 2: Normal Bucket with KMS Encryption
# ============================================
# inputs = {
#   bucket_name = "myapp-sensitive-data"
#   bucket_type = "normal"
#   environment = "prod"
#   
#   encryption_enabled = true
#   encryption_type   = "aws:kms"
#   kms_key_id       = "arn:aws:kms:us-east-1:123456789012:key/abc123"
#   
#   enable_secure_transport = true
#   versioning_enabled      = true
#   
#   tags = {
#     Application = "myapp"
#     Team        = "platform"
#     DataClass   = "sensitive"
#   }
# }

# ============================================
# Example 3: Access Log Bucket
# ============================================
# This creates a bucket specifically for storing S3 access logs
# from other buckets. Default lifecycle: delete logs after 365 days.

# inputs = {
#   bucket_name = "myapp-access-logs"
#   bucket_type = "access_log"
#   environment = "prod"
#   
#   encryption_enabled = true
#   encryption_type   = "AES256"
#   
#   enable_secure_transport = true
#   enable_lifecycle_policy  = true
#   
#   tags = {
#     Purpose = "access-logs"
#   }
# }

# ============================================
# Example 4: VPC Flow Log Bucket
# ============================================
# This creates a bucket for storing VPC Flow Logs.
# Default lifecycle: delete logs after 90 days.

# inputs = {
#   bucket_name = "myapp-vpc-flow-logs"
#   bucket_type = "vpc_flow_log"
#   environment = "prod"
#   
#   encryption_enabled = true
#   encryption_type   = "AES256"
#   
#   enable_secure_transport = true
#   enable_lifecycle_policy  = true
#   
#   vpc_flow_log_prefix = "vpc-flow-logs/"
#   
#   tags = {
#     Purpose = "vpc-flow-logs"
#   }
# }

# ============================================
# Example 5: Normal Bucket with Custom Lifecycle Rules
# ============================================
# Note: Default lifecycle rules include:
# - Abort incomplete multipart uploads (7 days)
# - Intelligent-Tiering transition (immediate)
# 
# You can override with custom rules if needed:
# inputs = {
#   bucket_name = "myapp-custom-bucket"
#   bucket_type = "normal"
#   environment = "prod"
#   
#   encryption_enabled = true
#   enable_secure_transport = true
#   
#   enable_lifecycle_policy = true
#   default_lifecycle_rules  = false  # Disable defaults
#   
#   lifecycle_rules = [
#     {
#       id     = "abort-multipart"
#       status = "Enabled"
#       abort_incomplete_multipart_upload = {
#         days_after_initiation = 7
#       }
#     },
#     {
#       id     = "intelligent-tiering"
#       status = "Enabled"
#       transitions = [
#         {
#           days          = 0
#           storage_class = "INTELLIGENT_TIERING"
#         }
#       ]
#     }
#   ]
#   
#   tags = {
#     Application = "myapp"
#   }
# }

# ============================================
# Example 6: Normal Bucket with Access Logging Enabled
# ============================================
# This creates a normal bucket and configures it to send
# access logs to an access log bucket.

# inputs = {
#   bucket_name = "myapp-data-bucket"
#   bucket_type = "normal"
#   environment = "prod"
#   
#   # Configure this bucket to send access logs to another bucket
#   access_log_bucket = "myapp-access-logs"  # Name of the access log bucket
#   access_log_prefix = "myapp-data-bucket/"  # Prefix for logs from this bucket
#   
#   encryption_enabled = true
#   enable_secure_transport = true
#   
#   tags = {
#     Application = "myapp"
#   }
# }

# ============================================
# Example 7: Bucket with Object Lock (Compliance)
# ============================================
# inputs = {
#   bucket_name = "myapp-compliance-bucket"
#   bucket_type = "normal"
#   environment = "prod"
#   
#   encryption_enabled = true
#   encryption_type   = "aws:kms"
#   kms_key_id       = "arn:aws:kms:us-east-1:123456789012:key/abc123"
#   
#   object_lock_enabled = true
#   object_lock_configuration = {
#     rule = {
#       default_retention = {
#         mode  = "GOVERNANCE"  # or "COMPLIANCE"
#         days  = 2555  # 7 years
#       }
#     }
#   }
#   
#   tags = {
#     Purpose     = "compliance"
#     DataClass   = "regulated"
#   }
# }

# ============================================
# Example 8: Minimal Configuration
# ============================================
# inputs = {
#   bucket_name = "myapp-simple-bucket"
#   bucket_type = "normal"
#   environment = "dev"
#   
#   # All security features enabled by default
#   # All defaults will be used
# }

