#!/bin/bash

set -e

# -----------------------------
# Check and Install Terraform
# -----------------------------
echo "🔍 Checking for Terraform..."
if ! command -v terraform &> /dev/null; then
  echo "🚀 Terraform not found. Installing..."
  curl -fsSL https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip -o terraform.zip
  unzip terraform.zip
  sudo mv terraform /usr/local/bin/
  rm terraform.zip
else
  echo "✅ Terraform is already installed."
fi

# -----------------------------
# Check and Install Helm
# -----------------------------
echo "🔍 Checking for Helm..."
if ! command -v helm &> /dev/null; then
  echo "🚀 Helm not found. Installing..."
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
else
  echo "✅ Helm is already installed."
fi

# -----------------------------
# Remote State Setup
# -----------------------------
BUCKET_NAME="my-terraform-state-bucket"
DYNAMODB_TABLE="terraform-locks"
REGION="us-east-1"

echo "🗂️ Ensuring S3 bucket exists: $BUCKET_NAME..."
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "📦 Creating S3 bucket: $BUCKET_NAME"
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" || true
else
  echo "✅ Bucket already exists."
fi

echo "🗂️ Ensuring DynamoDB table exists: $DYNAMODB_TABLE..."
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" &> /dev/null; then
  echo "📊 Creating DynamoDB table: $DYNAMODB_TABLE"
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "$REGION"
else
  echo "✅ DynamoDB table already exists."
fi

# -----------------------------
# Terraform Init
# -----------------------------
echo "🔧 Initializing Terraform..."
INIT_OUTPUT=$(mktemp)
if ! terraform init 2> "$INIT_OUTPUT"; then
  if grep -q "Backend configuration changed" "$INIT_OUTPUT"; then
    echo "⚠️  Backend configuration changed, reinitializing with -reconfigure..."
    terraform init -reconfigure
  else
    cat "$INIT_OUTPUT"
    echo "❌ Terraform init failed."
    exit 1
  fi
fi
rm -f "$INIT_OUTPUT"

echo "🚀 Phase 1: Creating EKS, VPC, IAM, ALB..."
terraform apply -auto-approve \
  -target=module.vpc \
  -target=module.eks \
  -target=module.iam \
  -target=module.alb \
  -target=module.sqs \
  -target=random_password.aurora_password \
  -target=random_password.jwt_secret

# -----------------------------
# Wait for EKS readiness
# -----------------------------
echo "⏳ Waiting for EKS cluster to be ready..."
aws eks wait cluster-active --region "$REGION" --name "restaurant-recommendation-cluster"
echo "✅ EKS cluster is active."

# -----------------------------
# Update kubeconfig
# -----------------------------
echo "🔧 Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --region "$REGION" --name "restaurant-recommendation-cluster"

# Optional: Test if Kubernetes API is reachable
echo "🔍 Verifying Kubernetes connection..."
kubectl get nodes || echo "⚠️ Kubernetes not ready yet"

# -----------------------------
# Phase 2: Apply Kubernetes-based modules
# -----------------------------
echo "🚀 Phase 2: Applying remaining Terraform resources..."
terraform apply -auto-approve