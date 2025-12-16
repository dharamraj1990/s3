# Commands to Create All Three Types of S3 Buckets

This document provides commands to create all three types of S3 buckets: Normal, Access Log, and VPC Flow Log.

## Prerequisites

- AWS credentials configured
- Terragrunt installed
- Terraform installed

## Method 1: Using the Automated Script (Recommended)

The easiest way is to use the provided script:

```bash
cd terragrunt-configs/s3
./create-buckets.sh [environment] [region] [project]
```

**Examples:**
```bash
# Using defaults (dev, us-east-1, myproject)
./create-buckets.sh

# Custom environment and region
./create-buckets.sh prod us-west-2 myapp

# Custom project name
./create-buckets.sh dev us-east-1 mycompany
```

## Method 2: Manual Step-by-Step Commands

### Step 1: Create Access Log Bucket (Create this first)

```bash
cd terragrunt-configs/s3/env/dev

export ENVIRONMENT="dev"
export AWS_REGION="us-east-1"
export PROJECT="myproject"
export S3_BUCKET_TYPE="access_log"
export S3_VERSIONING_ENABLED="true"
export S3_ENCRYPTION_ENABLED="true"
export S3_ENCRYPTION_TYPE="AES256"
export S3_ENABLE_SECURE_TRANSPORT="true"
export S3_ENABLE_LIFECYCLE_POLICY="true"
export S3_DEFAULT_LIFECYCLE_RULES="true"

terragrunt init
terragrunt plan
terragrunt apply
```

**Get the access log bucket name:**
```bash
ACCESS_LOG_BUCKET=$(terragrunt output -raw bucket_name)
echo "Access Log Bucket: $ACCESS_LOG_BUCKET"
```

### Step 2: Create Normal Bucket (with access logging)

```bash
# Still in terragrunt-configs/s3/env/dev

export S3_BUCKET_TYPE="normal"
export S3_ACCESS_LOG_BUCKET="$ACCESS_LOG_BUCKET"  # Use the bucket from Step 1
export S3_ACCESS_LOG_PREFIX="access-logs/"

terragrunt init
terragrunt plan
terragrunt apply
```

**Get the normal bucket name:**
```bash
NORMAL_BUCKET=$(terragrunt output -raw bucket_name)
echo "Normal Bucket: $NORMAL_BUCKET"
```

### Step 3: Create VPC Flow Log Bucket

```bash
# Still in terragrunt-configs/s3/env/dev

export S3_BUCKET_TYPE="vpc_flow_log"
export S3_ACCESS_LOG_BUCKET=""  # Clear for VPC flow log bucket
export S3_VPC_FLOW_LOG_PREFIX="vpc-flow-logs/"

terragrunt init
terragrunt plan
terragrunt apply
```

**Get the VPC flow log bucket name:**
```bash
VPC_FLOW_LOG_BUCKET=$(terragrunt output -raw bucket_name)
echo "VPC Flow Log Bucket: $VPC_FLOW_LOG_BUCKET"
```

## Method 3: Using Custom Bucket Names

If you want to specify custom bucket names instead of using the auto-generated naming convention:

### Access Log Bucket
```bash
export S3_BUCKET_NAME="my-custom-access-logs-bucket"
export S3_BUCKET_TYPE="access_log"
# ... other variables ...
terragrunt apply
```

### Normal Bucket
```bash
export S3_BUCKET_NAME="my-custom-normal-bucket"
export S3_BUCKET_TYPE="normal"
export S3_ACCESS_LOG_BUCKET="my-custom-access-logs-bucket"  # Reference the access log bucket
# ... other variables ...
terragrunt apply
```

### VPC Flow Log Bucket
```bash
export S3_BUCKET_NAME="my-custom-vpc-flow-logs-bucket"
export S3_BUCKET_TYPE="vpc_flow_log"
# ... other variables ...
terragrunt apply
```

## Quick Reference: All Commands in One Block

```bash
# Set common variables
export ENVIRONMENT="dev"
export AWS_REGION="us-east-1"
export PROJECT="myproject"

# 1. Access Log Bucket
cd terragrunt-configs/s3/env/dev
export S3_BUCKET_TYPE="access_log"
terragrunt apply
ACCESS_LOG_BUCKET=$(terragrunt output -raw bucket_name)

# 2. Normal Bucket
export S3_BUCKET_TYPE="normal"
export S3_ACCESS_LOG_BUCKET="$ACCESS_LOG_BUCKET"
terragrunt apply

# 3. VPC Flow Log Bucket
export S3_BUCKET_TYPE="vpc_flow_log"
export S3_ACCESS_LOG_BUCKET=""
terragrunt apply
```

## Verification

After creating all buckets, verify they exist:

```bash
# List all buckets
aws s3 ls

# Check bucket configuration
aws s3api get-bucket-versioning --bucket <bucket-name>
aws s3api get-bucket-encryption --bucket <bucket-name>
aws s3api get-bucket-logging --bucket <normal-bucket-name>
```

## Cleanup (Destroy All Buckets)

To destroy all buckets (in reverse order):

```bash
cd terragrunt-configs/s3/env/dev

# 1. Destroy VPC Flow Log Bucket
export S3_BUCKET_TYPE="vpc_flow_log"
terragrunt destroy

# 2. Destroy Normal Bucket
export S3_BUCKET_TYPE="normal"
terragrunt destroy

# 3. Destroy Access Log Bucket (last)
export S3_BUCKET_TYPE="access_log"
terragrunt destroy
```

## Notes

1. **Order Matters**: Create the access log bucket first, then the normal bucket (which references it), then the VPC flow log bucket.

2. **Bucket Naming**: If `S3_BUCKET_NAME` is not set, buckets will be auto-named using the pattern:
   - `${ENVIRONMENT}-${AWS_REGION}-${PROJECT}-${BUCKET_TYPE}-bucket`
   - Example: `dev-us-east-1-myproject-access-log-bucket`

3. **Access Logging**: The normal bucket will automatically send its access logs to the access log bucket when `S3_ACCESS_LOG_BUCKET` is set.

4. **Lifecycle Policies**: All buckets get default lifecycle policies (multipart cleanup + Intelligent-Tiering) unless disabled.

