#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".env" ]]; then
  # shellcheck disable=SC1091
  source .env
else
  echo "ERROR: .env not found. Copy .env.example to .env and fill values."
  exit 1
fi

SQL_FQDN="${SQL_SERVER_DEV}.database.windows.net"

# --- Resolve sqlcmd reliably on Windows Git Bash ---
SQLCMD_BIN="$(command -v sqlcmd 2>/dev/null || true)"

if [[ -z "$SQLCMD_BIN" ]]; then
  # Try common windows locations
  for p in \
    "/c/Program Files/SqlCmd/sqlcmd.exe" \
    "/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/180/Tools/Binn/sqlcmd.exe" \
    "/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/170/Tools/Binn/sqlcmd.exe" \
    "/c/Program Files/Microsoft SQL Server/160/Tools/Binn/sqlcmd.exe" \
    "/c/Program Files/Microsoft SQL Server/150/Tools/Binn/sqlcmd.exe"
  do
    if [[ -f "$p" ]]; then
      SQLCMD_BIN="$p"
      break
    fi
  done
fi

if [[ -z "$SQLCMD_BIN" ]]; then
  echo "ERROR: sqlcmd not found. Confirm installation and PATH."
  exit 1
fi

echo "Initializing DEV DB: ${SQL_FQDN} / ${SQL_DB_DEV}"
echo "Using sqlcmd: ${SQLCMD_BIN}"

run_sql() {
  local file="$1"
  echo "Running: $file"
  "$SQLCMD_BIN" -S "$SQL_FQDN" -d "$SQL_DB_DEV" -U "$SQL_ADMIN_USER_DEV" -P "$SQL_ADMIN_PASSWORD_DEV" -b -i "$file"
}

run_sql "data/sql/schema.sql"
run_sql "data/sql/indexes.sql"
run_sql "data/sql/views.sql"
run_sql "data/sql/migration_tables.sql"
run_sql "infra/scripts/seed-dev-data.sql"
run_sql "data/sql/sample-queries.sql"

echo "✅ DEV DB initialized."
