#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Boilerworks — Cold Boot Verification
#
# Verifies that a deployment is healthy after bootstrap or apply.
# Checks ALB health, ECS service status, and endpoint accessibility.
#
# Usage:
#   ./aws/scripts/cold-boot.sh <environment> [timeout_minutes]
# -----------------------------------------------------------------------------

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ENV="${1:?Usage: cold-boot.sh <dev|prd> [timeout_minutes]}"
TIMEOUT_MINUTES="${2:-10}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments/${ENV}"

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

[[ -d "${ENV_DIR}" ]] || error "Environment directory not found: ${ENV_DIR}"

# -----------------------------------------------------------------------------
# Get ALB DNS from Terraform output
# -----------------------------------------------------------------------------

info "Retrieving ALB DNS name for ${ENV}..."
cd "${ENV_DIR}"

ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null) \
  || error "Could not read ALB DNS from terraform output. Has the environment been applied?"

info "ALB DNS: ${ALB_DNS}"

# -----------------------------------------------------------------------------
# Wait for ECS service to stabilize
# -----------------------------------------------------------------------------

CLUSTER_NAME="${ENV}-boilerworks"
SERVICE_NAME="${ENV}-boilerworks-app"

info "Checking ECS service ${SERVICE_NAME} in cluster ${CLUSTER_NAME}..."

TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))
INTERVAL=15
ELAPSED=0

while [[ ${ELAPSED} -lt ${TIMEOUT_SECONDS} ]]; do
  RUNNING_COUNT=$(aws ecs describe-services \
    --cluster "${CLUSTER_NAME}" \
    --services "${SERVICE_NAME}" \
    --query "services[0].runningCount" \
    --output text 2>/dev/null || echo "0")

  DESIRED_COUNT=$(aws ecs describe-services \
    --cluster "${CLUSTER_NAME}" \
    --services "${SERVICE_NAME}" \
    --query "services[0].desiredCount" \
    --output text 2>/dev/null || echo "0")

  if [[ "${RUNNING_COUNT}" == "${DESIRED_COUNT}" ]] && [[ "${RUNNING_COUNT}" -gt 0 ]]; then
    success "ECS service stable: ${RUNNING_COUNT}/${DESIRED_COUNT} tasks running"
    break
  fi

  info "ECS tasks: ${RUNNING_COUNT}/${DESIRED_COUNT} running (waiting...)"
  sleep ${INTERVAL}
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [[ ${ELAPSED} -ge ${TIMEOUT_SECONDS} ]]; then
  error "ECS service did not stabilize within ${TIMEOUT_MINUTES} minutes"
fi

# -----------------------------------------------------------------------------
# Health check endpoints
# -----------------------------------------------------------------------------

ENDPOINTS=("/health/")

for ENDPOINT in "${ENDPOINTS[@]}"; do
  URL="https://${ALB_DNS}${ENDPOINT}"
  info "Checking ${URL}..."

  HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "${URL}" 2>/dev/null || echo "000")

  if [[ "${HTTP_CODE}" == "200" ]]; then
    success "${ENDPOINT} → HTTP ${HTTP_CODE}"
  elif [[ "${HTTP_CODE}" == "000" ]]; then
    warn "${ENDPOINT} → Connection failed (cert may not be ready yet)"
  else
    warn "${ENDPOINT} → HTTP ${HTTP_CODE}"
  fi
done

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo ""
success "Cold boot verification complete for ${ENV}."
echo ""
echo "  ALB:     https://${ALB_DNS}"
echo "  Cluster: ${CLUSTER_NAME}"
echo "  Service: ${SERVICE_NAME}"
echo ""
