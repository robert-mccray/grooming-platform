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

SQL_FQDN="${SQL_SERVER_DEV}.database.windows.net"

echo "Initializing DEV DB: $SQL_FQDN / $SQL_DB_DEV"

run_sql() {
  local file="$1"
  echo "Running: $file"
  sqlcmd -S "$SQL_FQDN" -d "$SQL_DB_DEV" -U "$SQL_ADMIN_USER_DEV" -P "$SQL_ADMIN_PASSWORD_DEV" -b -i "$file"
}

run_sql "data/sql/schema.sql"
run_sql "data/sql/indexes.sql"
run_sql "data/sql/views.sql"
run_sql "data/sql/migration_tables.sql"
run_sql "infra/scripts/seed-dev-data.sql"
run_sql "data/sql/sample-queries.sql"

echo "✅ DEV DB initialized."
