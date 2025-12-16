#!/bin/bash

# Script to create all three types of S3 buckets
# Usage: ./create-buckets.sh [environment] [region] [project]
#
# Note: This script uses Terragrunt workspaces to manage separate state for each bucket type.
# Each bucket type will be created in the same directory but with different workspace names.

set -e

ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
PROJECT="${3:-myproject}"

echo "Creating S3 buckets for environment: $ENVIRONMENT, region: $AWS_REGION, project: $PROJECT"
echo ""

# Set common environment variables
export ENVIRONMENT="$ENVIRONMENT"
export AWS_REGION="$AWS_REGION"
export PROJECT="$PROJECT"

# Base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAGRUNT_DIR="$BASE_DIR/env/$ENVIRONMENT"

# Common bucket configuration
export S3_VERSIONING_ENABLED="true"
export S3_ENCRYPTION_ENABLED="true"
export S3_ENCRYPTION_TYPE="AES256"
export S3_ENABLE_SECURE_TRANSPORT="true"
export S3_ENABLE_LIFECYCLE_POLICY="true"
export S3_DEFAULT_LIFECYCLE_RULES="true"

cd "$TERRAGRUNT_DIR"

# Step 1: Create Access Log Bucket (should be created first)
echo "=========================================="
echo "Step 1: Creating Access Log Bucket"
echo "=========================================="
export S3_BUCKET_NAME=""
export S3_BUCKET_TYPE="access_log"
export S3_ACCESS_LOG_BUCKET=""
export S3_ACCESS_LOG_PREFIX="access-logs/"

# Use workspace to separate state
terragrunt workspace select access-log 2>/dev/null || terragrunt workspace new access-log
terragrunt init
terragrunt plan -out=tfplan-access-log
terragrunt apply tfplan-access-log

# Get the access log bucket name
ACCESS_LOG_BUCKET_NAME=$(terragrunt output -raw bucket_name 2>/dev/null || echo "${ENVIRONMENT}-${AWS_REGION}-${PROJECT}-access-log-bucket")
echo "✓ Access Log Bucket created: $ACCESS_LOG_BUCKET_NAME"
echo ""

# Step 2: Create Normal Bucket (with access logging to access log bucket)
echo "=========================================="
echo "Step 2: Creating Normal Bucket"
echo "=========================================="
export S3_BUCKET_TYPE="normal"
export S3_ACCESS_LOG_BUCKET="$ACCESS_LOG_BUCKET_NAME"
export S3_ACCESS_LOG_PREFIX="access-logs/"

# Use workspace to separate state
terragrunt workspace select normal 2>/dev/null || terragrunt workspace new normal
terragrunt init
terragrunt plan -out=tfplan-normal
terragrunt apply tfplan-normal

NORMAL_BUCKET_NAME=$(terragrunt output -raw bucket_name 2>/dev/null || echo "${ENVIRONMENT}-${AWS_REGION}-${PROJECT}-normal-bucket")
echo "✓ Normal Bucket created: $NORMAL_BUCKET_NAME"
echo ""

# Step 3: Create VPC Flow Log Bucket
echo "=========================================="
echo "Step 3: Creating VPC Flow Log Bucket"
echo "=========================================="
export S3_BUCKET_TYPE="vpc_flow_log"
export S3_ACCESS_LOG_BUCKET=""  # Clear access log bucket for VPC flow log bucket
export S3_VPC_FLOW_LOG_PREFIX="vpc-flow-logs/"

# Use workspace to separate state
terragrunt workspace select vpc-flow-log 2>/dev/null || terragrunt workspace new vpc-flow-log
terragrunt init
terragrunt plan -out=tfplan-vpc-flow-log
terragrunt apply tfplan-vpc-flow-log

VPC_FLOW_LOG_BUCKET_NAME=$(terragrunt output -raw bucket_name 2>/dev/null || echo "${ENVIRONMENT}-${AWS_REGION}-${PROJECT}-vpc-flow-log-bucket")
echo "✓ VPC Flow Log Bucket created: $VPC_FLOW_LOG_BUCKET_NAME"
echo ""

echo "=========================================="
echo "All buckets created successfully!"
echo "=========================================="
echo "Access Log Bucket: $ACCESS_LOG_BUCKET_NAME"
echo "Normal Bucket: $NORMAL_BUCKET_NAME"
echo "VPC Flow Log Bucket: $VPC_FLOW_LOG_BUCKET_NAME"
echo ""
echo "Note: The Normal Bucket is configured to send access logs to: $ACCESS_LOG_BUCKET_NAME"
echo ""
echo "To manage individual buckets, use:"
echo "  terragrunt workspace select <workspace-name>"
echo "  Workspaces: access-log, normal, vpc-flow-log"

