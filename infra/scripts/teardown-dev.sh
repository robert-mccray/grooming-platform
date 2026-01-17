#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".env" ]]; then
  source .env
else
  echo "ERROR: .env not found."
  exit 1
fi

az account set --subscription "$AZ_SUBSCRIPTION_ID"

echo "⚠️ This will delete the DEV resource group: $RG_DEV"
echo "Type DELETE to confirm:"
read -r CONFIRM

if [[ "$CONFIRM" != "DELETE" ]]; then
  echo "Cancelled."
  exit 0
fi

az group delete --name "$RG_DEV" --yes --no-wait
echo "✅ DEV teardown initiated."
