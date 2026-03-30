#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Boilerworks — First-Time Infrastructure Bootstrap
#
# Creates the Terraform state backend (S3 + DynamoDB), then initializes
# all three environments so they're ready for plan/apply.
#
# Usage:
#   ./aws/scripts/bootstrap.sh [region]
#
# What it does:
#   1. Preflight checks (terraform, aws cli, credentials)
#   2. Create S3 bucket + DynamoDB table for state
#   3. terraform init for dev, stg, and prd
#   4. Print next steps
# -----------------------------------------------------------------------------

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REGION="${1:-us-west-2}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_DIR="${SCRIPT_DIR}/.."
TF_BACKEND_DIR="${AWS_DIR}/tf-backend"
ENVIRONMENTS=("dev" "stg" "prd")

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# -----------------------------------------------------------------------------
# Preflight checks
# -----------------------------------------------------------------------------

info "Running preflight checks..."

command -v terraform >/dev/null 2>&1 || error "terraform is not installed"
command -v aws >/dev/null 2>&1 || error "aws CLI is not installed"

TF_VERSION=$(terraform version -json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])" 2>/dev/null || terraform version | head -1 | grep -oE '[0-9]+\.[0-9]+')
info "Terraform version: ${TF_VERSION}"

info "Verifying AWS credentials..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
  || error "Failed to get AWS identity. Run 'aws configure' or set AWS_PROFILE."
success "Authenticated as account ${AWS_ACCOUNT_ID}"

# -----------------------------------------------------------------------------
# Step 1: Create Terraform state backend
# -----------------------------------------------------------------------------

echo ""
info "=== Step 1/2: Terraform State Backend ==="
info "Creating S3 bucket + DynamoDB table in ${REGION}..."

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
# Step 2: Initialize all environments
# -----------------------------------------------------------------------------

echo ""
info "=== Step 2/2: Initialize Environments ==="

INIT_FAILURES=()

for ENV in "${ENVIRONMENTS[@]}"; do
  ENV_DIR="${AWS_DIR}/environments/${ENV}"

  if [[ ! -d "${ENV_DIR}" ]]; then
    warn "Environment directory not found: ${ENV} (skipping)"
    continue
  fi

  info "Initializing ${ENV}..."
  if terraform -chdir="${ENV_DIR}" init -input=false >/dev/null 2>&1; then
    success "  ${ENV} initialized"
  else
    warn "  ${ENV} init failed (may need backend credentials for this account)"
    INIT_FAILURES+=("${ENV}")
  fi
done

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo ""
echo "============================================"

if [[ ${#INIT_FAILURES[@]} -eq 0 ]]; then
  success "Bootstrap complete. All environments initialized."
else
  warn "Bootstrap complete with warnings."
  warn "Failed to init: ${INIT_FAILURES[*]}"
  echo "  This is normal if environments use different AWS accounts."
  echo "  Run './run.sh init aws <env>' manually with the correct credentials."
fi

echo ""
info "Next steps:"
echo ""
echo "  1. Review the dev plan:"
echo "     ./run.sh plan aws dev"
echo ""
echo "  2. Apply dev when ready:"
echo "     ./run.sh apply aws dev"
echo ""
echo "  3. Verify deployment:"
echo "     ./aws/scripts/cold-boot.sh dev"
echo ""
echo "  Repeat for stg and prd when ready."
echo ""
success "Done."
