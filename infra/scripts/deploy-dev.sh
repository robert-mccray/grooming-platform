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

echo "Using subscription: $AZ_SUBSCRIPTION_ID"
az account set --subscription "$AZ_SUBSCRIPTION_ID"

echo "Deploying DEV infra to resource group: $RG_DEV"
az deployment group create \
  --resource-group "$RG_DEV" \
  --template-file "infra/bicep/main.bicep" \
  --parameters "@infra/env/dev.parameters.json" \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD_DEV" \
  --only-show-errors

echo "✅ DEV infra deployment complete."
