#!/bin/bash
# Initialize Terraform backend resources (S3 bucket and DynamoDB table)

set -e

AWS_PROFILE="${AWS_PROFILE:-459286107047_svc_data_prod}"
AWS_REGION="us-west-2"
BUCKET_NAME="gndataeng-terraform-state-prod"
DYNAMODB_TABLE="gndataeng-terraform-lock-prod"

echo "========================================="
echo "Initializing Terraform Backend"
echo "========================================="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Check if bucket exists
echo "Checking if S3 bucket exists..."
if aws s3 ls "s3://$BUCKET_NAME" --region $AWS_REGION 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION

    # Enable versioning
    echo "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled \
        --region $AWS_REGION

    # Enable encryption
    echo "Enabling encryption on S3 bucket..."
    aws s3api put-bucket-encryption \
        --bucket $BUCKET_NAME \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' \
        --region $AWS_REGION

    # Block public access
    echo "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket $BUCKET_NAME \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --region $AWS_REGION

    echo "✓ S3 bucket created successfully"
else
    echo "✓ S3 bucket already exists"
fi

# Check if DynamoDB table exists
echo ""
echo "Checking if DynamoDB table exists..."
if ! aws dynamodb describe-table \
    --table-name $DYNAMODB_TABLE \
    --region $AWS_REGION \
    >/dev/null 2>&1; then

    echo "Creating DynamoDB table: $DYNAMODB_TABLE"
    aws dynamodb create-table \
        --table-name $DYNAMODB_TABLE \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $AWS_REGION

    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists \
        --table-name $DYNAMODB_TABLE \
        --region $AWS_REGION

    echo "✓ DynamoDB table created successfully"
else
    echo "✓ DynamoDB table already exists"
fi

echo ""
echo "========================================="
echo "✓ Terraform backend initialized"
echo "========================================="
echo ""
echo "You can now run:"
echo "  cd terraform"
echo "  terraform init"
echo ""
