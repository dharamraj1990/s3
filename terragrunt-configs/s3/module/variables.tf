variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "bucket_type" {
  description = "Type of bucket: 'normal', 'access_log', or 'vpc_flow_log'"
  type        = string
  default     = "normal"
  validation {
    condition     = contains(["normal", "access_log", "vpc_flow_log"], var.bucket_type)
    error_message = "bucket_type must be one of: normal, access_log, vpc_flow_log"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy for the bucket"
  type        = bool
  default     = true
}

# Encryption Configuration
variable "encryption_enabled" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type: 'AES256' (SSE-S3) or 'aws:kms' (SSE-KMS)"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "encryption_type must be either 'AES256' or 'aws:kms'"
  }
}

variable "kms_key_id" {
  description = "KMS key ID or ARN for SSE-KMS encryption (required if encryption_type is 'aws:kms')"
  type        = string
  default     = null
}

# Public Access Block Configuration
variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

# Secure Transport (HTTPS Only) Policy
variable "enable_secure_transport" {
  description = "Enable secure transport policy (HTTPS only)"
  type        = bool
  default     = true
}

# Lifecycle Policy Configuration
variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id     = string
    status = string
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
  }))
  default = []
}

# Default lifecycle rules based on bucket type
variable "default_lifecycle_rules" {
  description = "Use default lifecycle rules based on bucket type"
  type        = bool
  default     = true
}

# Access Log Bucket Configuration
variable "access_log_bucket" {
  description = "Bucket name or ARN for storing access logs. For normal buckets, this is where access logs will be sent. For access_log bucket type, this is the target bucket that will send logs to this bucket."
  type        = string
  default     = null
}

variable "access_log_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = "access-logs/"
}

# VPC Flow Log Configuration
variable "vpc_flow_log_prefix" {
  description = "Prefix for VPC flow logs"
  type        = string
  default     = "vpc-flow-logs/"
}

# Additional Bucket Policy
variable "additional_bucket_policy" {
  description = "Additional bucket policy JSON (will be merged with secure transport policy)"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}

# MFA Delete
variable "mfa_delete" {
  description = "Enable MFA delete for versioning (requires MFA device)"
  type        = bool
  default     = false
}

# Object Lock Configuration
variable "object_lock_enabled" {
  description = "Enable object lock for the bucket"
  type        = bool
  default     = false
}

variable "object_lock_configuration" {
  description = "Object lock configuration"
  type = object({
    rule = object({
      default_retention = object({
        mode  = string
        days  = optional(number)
        years = optional(number)
      })
    })
  })
  default = null
}

