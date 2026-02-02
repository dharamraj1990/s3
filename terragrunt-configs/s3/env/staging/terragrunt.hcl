# Staging Environment Configuration for S3 Buckets
# This PR will trigger plan workflow on PR and apply on merge (no approval needed)
# Uses account_id 533269020590 from env.json
terraform {
  source = "../../module"
}

locals {
  # Read from environment variables
  aws_region   = get_env("AWS_REGION", get_env("AWS_DEFAULT_REGION", "us-east-1"))
  environment  = get_env("ENVIRONMENT", "staging")
  project      = get_env("PROJECT", get_env("PROJECT_NAME", ""))
  bucket_name_str = get_env("S3_BUCKET_NAME", "")
  bucket_type_str = get_env("S3_BUCKET_TYPE", "normal")
  
  # Generate bucket name with naming convention if not provided
  # Format: ${env}-${region}-${project}-${bucket-type}-${suffix}
  # Example: staging-us-east-1-myproject-access-log-bucket
  # Note: Replace underscores with hyphens for S3 bucket name compatibility
  bucket_type_sanitized = replace(local.bucket_type_str, "_", "-")
  base_bucket_name = local.bucket_name_str != "" ? local.bucket_name_str : (
    local.project != "" ? "${local.environment}-${local.aws_region}-${local.project}-${local.bucket_type_sanitized}-bucket" : 
    "${local.environment}-${local.aws_region}-${local.bucket_type_sanitized}-bucket"
  )
  
  # Bucket configuration from environment variables
  versioning_enabled = tobool(get_env("S3_VERSIONING_ENABLED", "true"))
  encryption_enabled = tobool(get_env("S3_ENCRYPTION_ENABLED", "true"))
  encryption_type = get_env("S3_ENCRYPTION_TYPE", "AES256")
  kms_key_id = get_env("S3_KMS_KEY_ID", "")
  
  # Public access block
  block_public_acls = tobool(get_env("S3_BLOCK_PUBLIC_ACLS", "true"))
  block_public_policy = tobool(get_env("S3_BLOCK_PUBLIC_POLICY", "true"))
  ignore_public_acls = tobool(get_env("S3_IGNORE_PUBLIC_ACLS", "true"))
  restrict_public_buckets = tobool(get_env("S3_RESTRICT_PUBLIC_BUCKETS", "true"))
  
  # Secure transport
  enable_secure_transport = tobool(get_env("S3_ENABLE_SECURE_TRANSPORT", "true"))
  
  # Lifecycle policy
  enable_lifecycle_policy = tobool(get_env("S3_ENABLE_LIFECYCLE_POLICY", "true"))
  default_lifecycle_rules = tobool(get_env("S3_DEFAULT_LIFECYCLE_RULES", "true"))
  
  # Access log configuration (for access_log bucket type)
  access_log_bucket = get_env("S3_ACCESS_LOG_BUCKET", "")
  access_log_prefix = get_env("S3_ACCESS_LOG_PREFIX", "access-logs/")
  
  # VPC Flow Log configuration
  vpc_flow_log_prefix = get_env("S3_VPC_FLOW_LOG_PREFIX", "vpc-flow-logs/")
  
  # Common tags
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terragrunt"
    Project     = local.project != "" ? local.project : "default"
  }
}

# Input values for the Terraform module
inputs = {
  bucket_name = local.base_bucket_name
  bucket_type = local.bucket_type_str
  environment = local.environment
  
  # Versioning
  versioning_enabled = local.versioning_enabled
  
  # Encryption
  encryption_enabled = local.encryption_enabled
  encryption_type    = local.encryption_type
  kms_key_id         = local.kms_key_id != "" ? local.kms_key_id : null
  
  # Public Access Block
  block_public_acls       = local.block_public_acls
  block_public_policy     = local.block_public_policy
  ignore_public_acls      = local.ignore_public_acls
  restrict_public_buckets = local.restrict_public_buckets
  
  # Secure Transport
  enable_secure_transport = local.enable_secure_transport
  
  # Lifecycle Policy
  enable_lifecycle_policy = local.enable_lifecycle_policy
  default_lifecycle_rules = local.default_lifecycle_rules
  
  # Access Log Configuration
  access_log_bucket = local.access_log_bucket != "" ? local.access_log_bucket : null
  access_log_prefix = local.access_log_prefix
  
  # VPC Flow Log Configuration
  vpc_flow_log_prefix = local.vpc_flow_log_prefix
  
  # Tags
  tags = local.common_tags
}

