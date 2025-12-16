# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Locals for bucket configuration
locals {
  # Default lifecycle rules based on bucket type
  # Only includes: multipart cleanup and intelligent tiering
  # IMPORTANT: All rules must have the same structure (all keys present) to avoid tuple type issues
  default_lifecycle_rules_map = {
    normal = [
      {
        id          = "abort-incomplete-multipart"
        status      = "Enabled"
        transitions = []
        abort_incomplete_multipart_upload = {
          days_after_initiation = 7
        }
      },
      {
        id     = "intelligent-tiering"
        status = "Enabled"
        transitions = [
          {
            days          = 0
            storage_class = "INTELLIGENT_TIERING"
          }
        ]
        abort_incomplete_multipart_upload = null
      }
    ]
    access_log = [
      {
        id          = "abort-incomplete-multipart"
        status      = "Enabled"
        transitions = []
        abort_incomplete_multipart_upload = {
          days_after_initiation = 7
        }
      },
      {
        id     = "intelligent-tiering"
        status = "Enabled"
        transitions = [
          {
            days          = 0
            storage_class = "INTELLIGENT_TIERING"
          }
        ]
        abort_incomplete_multipart_upload = null
      }
    ]
    vpc_flow_log = [
      {
        id          = "abort-incomplete-multipart"
        status      = "Enabled"
        transitions = []
        abort_incomplete_multipart_upload = {
          days_after_initiation = 7
        }
      },
      {
        id     = "intelligent-tiering"
        status = "Enabled"
        transitions = [
          {
            days          = 0
            storage_class = "INTELLIGENT_TIERING"
          }
        ]
        abort_incomplete_multipart_upload = null
      }
    ]
  }

  # Lifecycle rules selection
  # DEFINITIVE FIX: Define rules as separate locals, then combine
  # This avoids tuple type inference from list literals with mixed types

  # Define each rule as a separate local variable
  # This allows Terraform to handle type conversion properly
  # Define rules with consistent structure
  # Both rules must have the same type for abort_incomplete_multipart_upload
  # We'll use a union type approach - make it always an object, but use a special marker for "not set"
  rule_abort_multipart_raw = {
    id          = "abort-incomplete-multipart"
    status      = "Enabled"
    transitions = []
    abort_incomplete_multipart_upload = {
      days_after_initiation = 7
    }
  }

  rule_intelligent_tiering_raw = {
    id     = "intelligent-tiering"
    status = "Enabled"
    transitions = [
      {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    ]
    abort_incomplete_multipart_upload = null
  }

  # Normalize rules to ensure identical structure
  # Convert null to a special object that we'll filter out later, or keep as null but ensure type compatibility
  rule_abort_multipart = {
    id                                = local.rule_abort_multipart_raw.id
    status                            = local.rule_abort_multipart_raw.status
    transitions                       = local.rule_abort_multipart_raw.transitions
    abort_incomplete_multipart_upload = local.rule_abort_multipart_raw.abort_incomplete_multipart_upload
  }

  rule_intelligent_tiering = {
    id                                = local.rule_intelligent_tiering_raw.id
    status                            = local.rule_intelligent_tiering_raw.status
    transitions                       = local.rule_intelligent_tiering_raw.transitions
    abort_incomplete_multipart_upload = local.rule_intelligent_tiering_raw.abort_incomplete_multipart_upload
  }

  # Lifecycle rules - DEFINE RULES DIRECTLY IN RESOURCE
  # Avoid creating any list/tuple/map with incompatible types
  # Instead, use conditional dynamic blocks in the resource itself
  
  use_default_rules = (var.bucket_type == "normal" || var.bucket_type == "access_log" || var.bucket_type == "vpc_flow_log") && var.default_lifecycle_rules && var.enable_lifecycle_policy
  
  # Track which rules to create (for use in resource)
  create_abort_multipart_rule = local.use_default_rules && length(var.lifecycle_rules) == 0
  create_intelligent_tiering_rule = local.use_default_rules && length(var.lifecycle_rules) == 0
  
  # For custom rules
  has_custom_rules = length(var.lifecycle_rules) > 0 && var.enable_lifecycle_policy
  custom_rules = var.lifecycle_rules

  # Secure transport policy (HTTPS only) - for normal and access_log buckets
  secure_transport_policy = var.enable_secure_transport ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:*"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  }) : null

  # S3 Access Log bucket policy - allows S3 logging service to write access logs
  # This policy allows logging.s3.amazonaws.com to write access logs from any bucket in the same account
  access_log_policy = var.bucket_type == "access_log" ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "S3ServerAccessLogsPolicy"
          Effect = "Allow"
          Principal = {
            Service = "logging.s3.amazonaws.com"
          }
          Action = [
            "s3:PutObject",
            "s3:GetBucketAcl"
          ]
          Resource = [
            "${aws_s3_bucket.main.arn}/*",
            aws_s3_bucket.main.arn
          ]
          Condition = {
            StringEquals = {
              "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            }
            ArnLike = {
              "aws:SourceArn" = "arn:aws:s3:::*"
            }
          }
        }
      ],
      var.enable_secure_transport ? [
        {
          Sid       = "DenyInsecureConnections"
          Effect    = "Deny"
          Principal = "*"
          Action = [
            "s3:*"
          ]
          Resource = [
            "${aws_s3_bucket.main.arn}",
            "${aws_s3_bucket.main.arn}/*"
          ]
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        }
      ] : []
    )
  }) : null

  # VPC Flow Log bucket policy - allows AWS log delivery service to write logs
  vpc_flow_log_policy = var.bucket_type == "vpc_flow_log" ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "AWSLogDeliveryWrite"
          Effect = "Allow"
          Principal = {
            Service = "delivery.logs.amazonaws.com"
          }
          Action = [
            "s3:PutObject",
            "s3:GetBucketAcl",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.main.arn,
            "${aws_s3_bucket.main.arn}/*"
          ]
          Condition = {
            StringEquals = {
              "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            }
          }
        }
      ],
      var.enable_secure_transport ? [
        {
          Sid       = "DenyInsecureConnections"
          Effect    = "Deny"
          Principal = "*"
          Action = [
            "s3:*"
          ]
          Resource = [
            "${aws_s3_bucket.main.arn}",
            "${aws_s3_bucket.main.arn}/*"
          ]
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        }
      ] : []
    )
  }) : null

  # Determine which bucket policy to use based on bucket type
  # For Access Log buckets, use the Access Log policy
  # For VPC Flow Log buckets, use the VPC Flow Log policy
  # For Normal buckets, use secure transport policy (or merge with additional policy)
  bucket_policy = var.bucket_type == "access_log" ? local.access_log_policy : (
    var.bucket_type == "vpc_flow_log" ? local.vpc_flow_log_policy : (
      var.additional_bucket_policy != null ? jsonencode({
        Version = "2012-10-17"
        Statement = concat(
          var.enable_secure_transport ? [
            {
              Sid       = "DenyInsecureConnections"
              Effect    = "Deny"
              Principal = "*"
              Action = [
                "s3:*"
              ]
              Resource = [
                "${aws_s3_bucket.main.arn}",
                "${aws_s3_bucket.main.arn}/*"
              ]
              Condition = {
                Bool = {
                  "aws:SecureTransport" = "false"
                }
              }
            }
          ] : [],
          jsondecode(var.additional_bucket_policy).Statement
        )
      }) : local.secure_transport_policy
    )
  )

  # Encryption configuration
  encryption_configuration = var.encryption_enabled ? {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = var.encryption_type
        kms_master_key_id = var.encryption_type == "aws:kms" && var.kms_key_id != null ? var.kms_key_id : null
      }
      bucket_key_enabled = var.encryption_type == "aws:kms" ? true : null
    }
  } : null

  # Common tags
  common_tags = merge(
    {
      Environment = var.environment
      BucketType  = var.bucket_type
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = false

  tags = local.common_tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Disabled"
    mfa_delete = var.mfa_delete && var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# S3 Bucket Server-Side Encryption Configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.encryption_enabled ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type
      kms_master_key_id = var.encryption_type == "aws:kms" && var.kms_key_id != null ? var.kms_key_id : null
    }
    bucket_key_enabled = var.encryption_type == "aws:kms" ? true : false
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# S3 Bucket Policy (Secure Transport)
resource "aws_s3_bucket_policy" "main" {
  count = local.bucket_policy != null ? 1 : 0

  bucket = aws_s3_bucket.main.id
  policy = local.bucket_policy

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# S3 Bucket Lifecycle Configuration
# Use conditional dynamic blocks to avoid tuple/list type issues
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = (local.has_custom_rules || local.use_default_rules) ? 1 : 0

  bucket = aws_s3_bucket.main.id

  # Custom rules (if provided)
  dynamic "rule" {
    for_each = local.has_custom_rules ? local.custom_rules : []
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "transition" {
        for_each = try(rule.value.transitions, [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_incomplete_multipart_upload, null) != null ? [rule.value.abort_incomplete_multipart_upload] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }

  # Default rule 1: Abort incomplete multipart upload
  dynamic "rule" {
    for_each = local.create_abort_multipart_rule ? [1] : []
    content {
      id     = local.rule_abort_multipart.id
      status = local.rule_abort_multipart.status

      abort_incomplete_multipart_upload {
        days_after_initiation = local.rule_abort_multipart.abort_incomplete_multipart_upload.days_after_initiation
      }
    }
  }

  # Default rule 2: Intelligent Tiering
  dynamic "rule" {
    for_each = local.create_intelligent_tiering_rule ? [1] : []
    content {
      id     = local.rule_intelligent_tiering.id
      status = local.rule_intelligent_tiering.status

      transition {
        days          = local.rule_intelligent_tiering.transitions[0].days
        storage_class = local.rule_intelligent_tiering.transitions[0].storage_class
      }
    }
  }
}

# S3 Bucket Object Lock Configuration
resource "aws_s3_bucket_object_lock_configuration" "main" {
  count = var.object_lock_enabled && var.object_lock_configuration != null ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    default_retention {
      mode  = var.object_lock_configuration.rule.default_retention.mode
      days  = var.object_lock_configuration.rule.default_retention.days
      years = var.object_lock_configuration.rule.default_retention.years
    }
  }
}

# S3 Bucket Logging Configuration
# This configures WHERE this bucket's access logs are sent
# For normal buckets, automatically enable logging to access_log_bucket if provided
# For access_log buckets themselves, this is typically not needed
# For vpc_flow_log buckets, logging is handled by the VPC Flow Log resource
resource "aws_s3_bucket_logging" "main" {
  count = var.access_log_bucket != null && var.bucket_type == "normal" ? 1 : 0

  bucket = aws_s3_bucket.main.id

  target_bucket = var.access_log_bucket
  target_prefix = var.access_log_prefix
}

# Note: For VPC Flow Log buckets, the VPC Flow Log resource itself should reference this bucket
# This module just creates the bucket with appropriate configuration

