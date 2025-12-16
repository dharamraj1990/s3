# S3 Bucket Terraform Module

A comprehensive Terraform module for creating secure S3 buckets with multiple bucket types, encryption, lifecycle policies, and security best practices.

## Features

- **Three Bucket Types**: Normal bucket, Access Log bucket, and VPC Flow Log bucket
- **Security Features**:
  - Public Access Block (all four settings configurable)
  - Server-Side Encryption (SSE-S3 or SSE-KMS)
  - Secure Transport Policy (HTTPS only)
  - Versioning support
  - MFA Delete (optional)
  - Object Lock (optional)
- **Lifecycle Policies**: Automatic transitions and expiration rules
- **Bucket Logging**: Configurable access logging
- **Customizable**: Extensive configuration options for all features

## Module Structure

```
s3/
├── module/
│   ├── main.tf           # Main S3 bucket resources
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   └── versions.tf        # Provider requirements
├── env/
│   └── dev/
│       └── terragrunt.hcl # Environment configuration
└── README.md              # This file
```

## Bucket Types

### 1. Normal Bucket
Standard S3 bucket for general use with lifecycle policies for cost optimization. When `access_log_bucket` is provided, the bucket will automatically be configured to send its access logs to the specified access log bucket.

**Default Lifecycle Rules:**
- Abort incomplete multipart uploads after 7 days
- Intelligent-Tiering transition (immediate, automatic cost optimization)

### 2. Access Log Bucket
Bucket specifically configured for storing S3 access logs from other buckets. This bucket type automatically includes a bucket policy that allows the S3 logging service (`logging.s3.amazonaws.com`) to write access logs to the bucket.

**Bucket Policy:**
- Allows `logging.s3.amazonaws.com` to `PutObject` and `GetBucketAcl`
- Includes account-based condition for security
- Includes secure transport policy (HTTPS only) if enabled

**Default Lifecycle Rules:**
- Abort incomplete multipart uploads after 7 days
- Intelligent-Tiering transition (immediate, automatic cost optimization)

### 3. VPC Flow Log Bucket
Bucket configured for storing VPC Flow Logs. This bucket type automatically includes a bucket policy that allows the AWS log delivery service (`delivery.logs.amazonaws.com`) to write logs to the bucket.

**Bucket Policy:**
- Allows `delivery.logs.amazonaws.com` to `PutObject`, `GetBucketAcl`, and `ListBucket`
- Includes account-based condition for security
- Includes secure transport policy (HTTPS only) if enabled

**Default Lifecycle Rules:**
- Abort incomplete multipart uploads after 7 days
- Intelligent-Tiering transition (immediate, automatic cost optimization)

## Usage

### Basic Example (Normal Bucket)

```hcl
# terragrunt-configs/s3/env/dev/terragrunt.hcl
terraform {
  source = "../../module"
}

inputs = {
  bucket_name = "my-secure-bucket"
  bucket_type = "normal"
  environment = "dev"
  
  # Encryption
  encryption_enabled = true
  encryption_type   = "AES256"  # or "aws:kms"
  
  # Security
  enable_secure_transport = true
  
  # Lifecycle
  enable_lifecycle_policy = true
}
```

### Normal Bucket with Access Logging

```hcl
inputs = {
  bucket_name = "my-bucket"
  bucket_type = "normal"
  environment = "dev"
  
  # Configure access logging - this bucket will send its logs to the access log bucket
  access_log_bucket = "my-access-logs-bucket"
  access_log_prefix = "access-logs/"
}
```

### Access Log Bucket Example

```hcl
inputs = {
  bucket_name = "my-access-logs-bucket"
  bucket_type = "access_log"
  environment = "dev"
  
  # Note: For access_log bucket type, access_log_bucket is not used
  # This bucket receives logs from other buckets that reference it
}
```

### VPC Flow Log Bucket Example

```hcl
inputs = {
  bucket_name = "my-vpc-flow-logs-bucket"
  bucket_type = "vpc_flow_log"
  environment = "dev"
  
  vpc_flow_log_prefix = "vpc-flow-logs/"
}
```

### With KMS Encryption

```hcl
inputs = {
  bucket_name = "my-encrypted-bucket"
  bucket_type = "normal"
  environment = "dev"
  
  encryption_enabled = true
  encryption_type   = "aws:kms"
  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}
```

### Custom Lifecycle Rules

```hcl
inputs = {
  bucket_name = "my-bucket"
  bucket_type = "normal"
  environment = "dev"
  
  enable_lifecycle_policy = true
  default_lifecycle_rules = false  # Disable defaults
  
  lifecycle_rules = [
    {
      id     = "custom-rule-1"
      status = "Enabled"
      expiration = {
        days = 180
      }
      transitions = [
        {
          days          = 60
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]
    }
  ]
}
```

## Environment Variables

The module can be configured using environment variables when using Terragrunt:

```bash
# Basic Configuration
export S3_BUCKET_NAME="my-bucket"
export S3_BUCKET_TYPE="normal"  # normal, access_log, or vpc_flow_log
export ENVIRONMENT="dev"
export AWS_REGION="us-east-1"

# Encryption
export S3_ENCRYPTION_ENABLED="true"
export S3_ENCRYPTION_TYPE="AES256"  # or "aws:kms"
export S3_KMS_KEY_ID="arn:aws:kms:..."  # Required if encryption_type is aws:kms

# Public Access Block
export S3_BLOCK_PUBLIC_ACLS="true"
export S3_BLOCK_PUBLIC_POLICY="true"
export S3_IGNORE_PUBLIC_ACLS="true"
export S3_RESTRICT_PUBLIC_BUCKETS="true"

# Secure Transport
export S3_ENABLE_SECURE_TRANSPORT="true"

# Lifecycle Policy
export S3_ENABLE_LIFECYCLE_POLICY="true"
export S3_DEFAULT_LIFECYCLE_RULES="true"

# Versioning
export S3_VERSIONING_ENABLED="true"
```

## Security Features

### 1. Public Access Block
All four public access block settings are enabled by default:
- Block public ACLs
- Block public bucket policies
- Ignore public ACLs
- Restrict public buckets

### 2. Secure Transport Policy
The module automatically creates a bucket policy that denies all non-HTTPS connections:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureConnections",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::bucket-name",
        "arn:aws:s3:::bucket-name/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

### 3. Server-Side Encryption
- **SSE-S3 (AES256)**: Default encryption using S3-managed keys
- **SSE-KMS**: Encryption using AWS KMS keys (requires `kms_key_id`)

### 4. Versioning
Versioning is enabled by default to protect against accidental deletion or overwrites.

## Lifecycle Policies

### Default Lifecycle Rules by Bucket Type

All bucket types use the same default lifecycle rules:

1. **Abort Incomplete Multipart Uploads**: Automatically cleans up incomplete multipart uploads after 7 days to prevent storage costs from abandoned uploads.

2. **Intelligent-Tiering**: Automatically transitions objects to Intelligent-Tiering storage class immediately (0 days). Intelligent-Tiering automatically moves objects between access tiers (Frequent Access, Infrequent Access, Archive Instant Access, Deep Archive Access) based on access patterns, optimizing costs without performance impact.

**Benefits of Intelligent-Tiering:**
- Automatic cost optimization based on access patterns
- No retrieval fees for accessing objects
- No performance impact
- Suitable for objects with unknown or changing access patterns

### Custom Lifecycle Rules

You can define custom lifecycle rules using the `lifecycle_rules` variable:

```hcl
lifecycle_rules = [
  {
    id     = "rule-1"
    status = "Enabled"
    transitions = [
      {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    ]
    abort_incomplete_multipart_upload = {
      days_after_initiation = 7
    }
  }
]
```

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `bucket_name` | Name of the S3 bucket | `string` | - | Yes |
| `bucket_type` | Type: normal, access_log, or vpc_flow_log | `string` | `"normal"` | No |
| `environment` | Environment name | `string` | - | Yes |
| `versioning_enabled` | Enable versioning | `bool` | `true` | No |
| `encryption_enabled` | Enable encryption | `bool` | `true` | No |
| `encryption_type` | AES256 or aws:kms | `string` | `"AES256"` | No |
| `kms_key_id` | KMS key ID for SSE-KMS | `string` | `null` | No |
| `block_public_acls` | Block public ACLs | `bool` | `true` | No |
| `block_public_policy` | Block public policies | `bool` | `true` | No |
| `ignore_public_acls` | Ignore public ACLs | `bool` | `true` | No |
| `restrict_public_buckets` | Restrict public buckets | `bool` | `true` | No |
| `enable_secure_transport` | Enable HTTPS-only policy | `bool` | `true` | No |
| `enable_lifecycle_policy` | Enable lifecycle policy | `bool` | `true` | No |
| `default_lifecycle_rules` | Use default lifecycle rules | `bool` | `true` | No |
| `lifecycle_rules` | Custom lifecycle rules | `list(object)` | `[]` | No |
| `access_log_bucket` | Target bucket for access logs | `string` | `null` | No |
| `access_log_prefix` | Prefix for access logs | `string` | `"access-logs/"` | No |
| `vpc_flow_log_prefix` | Prefix for VPC flow logs | `string` | `"vpc-flow-logs/"` | No |
| `additional_bucket_policy` | Additional bucket policy JSON | `string` | `null` | No |
| `tags` | Tags to apply | `map(string)` | `{}` | No |
| `mfa_delete` | Enable MFA delete | `bool` | `false` | No |
| `object_lock_enabled` | Enable object lock | `bool` | `false` | No |

## Outputs

| Output | Description |
|--------|-------------|
| `bucket_id` | ID of the S3 bucket |
| `bucket_arn` | ARN of the S3 bucket |
| `bucket_domain_name` | Domain name of the bucket |
| `bucket_regional_domain_name` | Regional domain name |
| `bucket_hosted_zone_id` | Route 53 hosted zone ID |
| `bucket_name` | Name of the bucket |
| `versioning_enabled` | Whether versioning is enabled |
| `encryption_enabled` | Whether encryption is enabled |
| `encryption_type` | Type of encryption used |
| `kms_key_id` | KMS key ID (if applicable) |
| `public_access_block` | Public access block configuration |
| `secure_transport_enabled` | Whether secure transport is enabled |
| `lifecycle_policy_enabled` | Whether lifecycle policy is enabled |
| `bucket_type` | Type of bucket |

## Examples

### Example 1: Secure Application Bucket

```hcl
inputs = {
  bucket_name = "myapp-data-bucket"
  bucket_type = "normal"
  environment = "prod"
  
  encryption_enabled = true
  encryption_type   = "aws:kms"
  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/abc123"
  
  enable_secure_transport = true
  versioning_enabled      = true
  
  enable_lifecycle_policy = true
  default_lifecycle_rules  = true
  
  tags = {
    Application = "myapp"
    Team        = "platform"
  }
}
```

### Example 2: Access Log Bucket

```hcl
inputs = {
  bucket_name = "myapp-access-logs"
  bucket_type = "access_log"
  environment = "prod"
  
  encryption_enabled = true
  encryption_type   = "AES256"
  
  enable_secure_transport = true
  enable_lifecycle_policy = true
  
  tags = {
    Purpose = "access-logs"
  }
}
```

### Example 3: VPC Flow Log Bucket

```hcl
inputs = {
  bucket_name = "myapp-vpc-flow-logs"
  bucket_type = "vpc_flow_log"
  environment = "prod"
  
  encryption_enabled = true
  encryption_type   = "AES256"
  
  enable_secure_transport = true
  enable_lifecycle_policy = true
  
  vpc_flow_log_prefix = "vpc-flow-logs/"
  
  tags = {
    Purpose = "vpc-flow-logs"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- Terragrunt >= 0.45 (for environment configuration)

## Best Practices

1. **Always enable encryption**: Use SSE-S3 for general use, SSE-KMS for sensitive data
2. **Enable secure transport**: Always require HTTPS connections
3. **Use lifecycle policies**: Automatically manage object lifecycle to reduce costs
4. **Enable versioning**: Protect against accidental deletion
5. **Block public access**: Use public access block settings
6. **Use appropriate bucket types**: Choose the right bucket type for your use case
7. **Tag resources**: Apply consistent tagging for cost allocation and management

## Security Considerations

- All buckets are created with public access blocked by default
- Secure transport (HTTPS only) is enabled by default
- Encryption is enabled by default (SSE-S3)
- Versioning is enabled by default for data protection
- Lifecycle policies help manage costs and compliance

## Troubleshooting

### Bucket name already exists
S3 bucket names must be globally unique. Choose a different name or add a unique suffix.

### KMS key not found
If using SSE-KMS, ensure the KMS key exists and the bucket has permissions to use it.

### Secure transport policy errors
Ensure the bucket policy is correctly formatted. The module automatically creates the secure transport policy.

## License

This module is provided as-is for use in your infrastructure.

