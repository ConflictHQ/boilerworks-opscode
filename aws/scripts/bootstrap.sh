#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Boilerworks — First-Time Infrastructure Bootstrap
#
# Creates a Terraform state backend (S3 + DynamoDB) per environment, then
# initializes each one. Supports multi-account / AWS Organizations.
#
# Usage:
#   ./aws/scripts/bootstrap.sh <dev|stg|prd|all>
#
# Configuration is read from aws/config.env (PROJECT, AWS_REGION, OWNER).
#
# For multi-account setups, switch AWS_PROFILE between runs:
#   AWS_PROFILE=myproject-dev-infra ./aws/scripts/bootstrap.sh dev
#   AWS_PROFILE=myproject-prd-infra ./aws/scripts/bootstrap.sh prd
# -----------------------------------------------------------------------------

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET="${1:?Usage: bootstrap.sh <dev|stg|prd|all>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_DIR="${SCRIPT_DIR}/.."
CONFIG_FILE="${AWS_DIR}/config.env"
TF_BACKEND_MODULE="${AWS_DIR}/modules/tf-backend-bootstrap"

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Load config
[[ -f "${CONFIG_FILE}" ]] || error "Config not found: ${CONFIG_FILE}"
# shellcheck source=/dev/null
source "${CONFIG_FILE}"

info "Config: PROJECT=${PROJECT} REGION=${AWS_REGION} OWNER=${OWNER}"

# Resolve environment list
if [[ "${TARGET}" == "all" ]]; then
  ENVIRONMENTS=("dev" "stg" "prd")
else
  [[ "${TARGET}" =~ ^(dev|stg|prd)$ ]] || error "Invalid environment: ${TARGET}. Must be dev, stg, prd, or all."
  ENVIRONMENTS=("${TARGET}")
fi

# -----------------------------------------------------------------------------
# Preflight
# -----------------------------------------------------------------------------

info "Running preflight checks..."
command -v terraform >/dev/null 2>&1 || error "terraform is not installed"
command -v aws >/dev/null 2>&1 || error "aws CLI is not installed"

info "Verifying AWS credentials..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
  || error "Failed to get AWS identity. Run 'aws configure' or set AWS_PROFILE."
success "Authenticated as account ${AWS_ACCOUNT_ID}"

# -----------------------------------------------------------------------------
# Bootstrap each environment
# -----------------------------------------------------------------------------

for ENV in "${ENVIRONMENTS[@]}"; do
  echo ""
  info "========================================="
  info "Bootstrapping: ${ENV} (account ${AWS_ACCOUNT_ID}, region ${AWS_REGION})"
  info "========================================="

  ENV_PROJECT="${PROJECT}-${ENV}"
  ENV_DIR="${AWS_DIR}/environments/${ENV}"

  [[ -d "${ENV_DIR}" ]] || { warn "Environment directory not found: ${ENV_DIR} (skipping)"; continue; }

  # --- Create state backend ---
  info "Creating state backend: tf-state.${ENV_PROJECT}.net"

  WORK_DIR=$(mktemp -d)

  cat > "${WORK_DIR}/main.tf" << EOF
module "backend" {
  source       = "${TF_BACKEND_MODULE}"
  project_name = "${ENV_PROJECT}"
  region       = "${AWS_REGION}"
  tags = {
    Service     = "${PROJECT}"
    Environment = "${ENV}"
    Owner       = "${OWNER}"
    ManagedBy   = "terraform"
  }
}
output "bucket_name" { value = module.backend.bucket_name }
output "table_name"  { value = module.backend.dynamodb_table_name }
EOF

  terraform -chdir="${WORK_DIR}" init -input=false >/dev/null 2>&1
  terraform -chdir="${WORK_DIR}" apply -auto-approve -input=false

  BUCKET=$(terraform -chdir="${WORK_DIR}" output -raw bucket_name)
  TABLE=$(terraform -chdir="${WORK_DIR}" output -raw table_name)

  rm -rf "${WORK_DIR}"

  success "State backend for ${ENV}:"
  echo "  S3 Bucket:       ${BUCKET}"
  echo "  DynamoDB Table:  ${TABLE}"
  echo "  Region:          ${AWS_REGION}"

  # --- Initialize environment ---
  info "Initializing ${ENV} environment..."
  if terraform -chdir="${ENV_DIR}" init -input=false \
    -backend-config="bucket=${BUCKET}" \
    -backend-config="dynamodb_table=${TABLE}" \
    -backend-config="key=terraform.tfstate" \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="encrypt=true" >/dev/null 2>&1; then
    success "${ENV} initialized"
  else
    warn "${ENV} init failed — check backend config"
  fi
done

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo ""
echo "============================================"
success "Bootstrap complete for: ${ENVIRONMENTS[*]}"
echo ""
info "Next steps:"
echo ""
for ENV in "${ENVIRONMENTS[@]}"; do
  echo "  ./run.sh plan aws ${ENV}"
done
echo ""
success "Done."
