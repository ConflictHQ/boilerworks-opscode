#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Boilerworks — First-Time Infrastructure Bootstrap
#
# Sets up the Terraform state backend (S3 + DynamoDB), then initializes
# and applies the chosen environment.
#
# Usage:
#   ./aws/scripts/bootstrap.sh [region]
# -----------------------------------------------------------------------------

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REGION="${1:-us-west-2}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_BACKEND_DIR="${SCRIPT_DIR}/../tf-backend"

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# -----------------------------------------------------------------------------
# Preflight checks
# -----------------------------------------------------------------------------

command -v terraform >/dev/null 2>&1 || error "terraform is not installed"
command -v aws >/dev/null 2>&1 || error "aws CLI is not installed"

info "Verifying AWS credentials..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
  || error "Failed to get AWS identity. Run 'aws configure' or set AWS_PROFILE."
success "Authenticated as account ${AWS_ACCOUNT_ID}"

# -----------------------------------------------------------------------------
# Step 1: Create Terraform state backend
# -----------------------------------------------------------------------------

info "Bootstrapping Terraform state backend in ${REGION}..."

cd "${TF_BACKEND_DIR}"

terraform init -input=false

terraform apply \
  -var="region=${REGION}" \
  -auto-approve \
  -input=false

BUCKET_NAME=$(terraform output -raw bucket_name)
TABLE_NAME=$(terraform output -raw dynamodb_table_name)

success "State backend created:"
echo "  S3 Bucket:      ${BUCKET_NAME}"
echo "  DynamoDB Table:  ${TABLE_NAME}"
echo "  Region:          ${REGION}"

# -----------------------------------------------------------------------------
# Step 2: Summary
# -----------------------------------------------------------------------------

echo ""
info "Bootstrap complete. Next steps:"
echo ""
echo "  1. Initialize the dev environment:"
echo "     ./run.sh init aws dev"
echo ""
echo "  2. Review the plan:"
echo "     ./run.sh plan aws dev"
echo ""
echo "  3. Apply when ready:"
echo "     ./run.sh apply aws dev"
echo ""
success "Done."
