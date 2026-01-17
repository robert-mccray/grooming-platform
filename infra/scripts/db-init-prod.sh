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

SQL_FQDN="${SQL_SERVER_PROD}.database.windows.net"

run_sql() {
  local file="$1"
  echo "Running: $file"
  sqlcmd -S "$SQL_FQDN" -d "$SQL_DB_PROD" -U "$SQL_ADMIN_USER_PROD" -P "$SQL_ADMIN_PASSWORD_PROD" -b -i "$file"
}

run_sql "data/sql/schema.sql"
run_sql "data/sql/indexes.sql"
run_sql "data/sql/views.sql"
run_sql "data/sql/migration_tables.sql"

echo "✅ PROD DB initialized (no seed data applied)."
