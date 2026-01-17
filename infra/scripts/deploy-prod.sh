#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".env" ]]; then
  source .env
else
  echo "ERROR: .env not found. Copy .env.example to .env and fill values."
  exit 1
fi

az account set --subscription "$AZ_SUBSCRIPTION_ID"

echo "Deploying PROD infra to resource group: $RG_PROD"
az deployment group create \
  --resource-group "$RG_PROD" \
  --template-file "infra/bicep/main.bicep" \
  --parameters "@infra/env/prod.parameters.json" \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD_PROD" \
  --only-show-errors

echo "✅ PROD infra deployment complete."
