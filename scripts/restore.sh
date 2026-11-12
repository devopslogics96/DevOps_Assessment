#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf 'Usage: %s <backup.sql> [new_database_name]\n' "${0##*/}" >&2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
backup_input="$1"

if [[ ! -f "$backup_input" ]]; then
  printf 'Backup file not found: %s\n' "$backup_input" >&2
  exit 1
fi

backup_file="$(cd -- "$(dirname -- "$backup_input")" && pwd)/$(basename -- "$backup_input")"
if [[ ! -s "$backup_file" ]]; then
  printf 'Backup file is empty: %s\n' "$backup_file" >&2
  exit 1
fi

if [[ $# -eq 2 ]]; then
  target_database="$2"
else
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  target_database="app_restore_${timestamp}"
fi

if [[ ! "$target_database" =~ ^[A-Za-z][A-Za-z0-9_]{0,63}$ ]]; then
  printf 'Database name must start with a letter and contain only letters, digits, or underscores (max 64 characters).\n' >&2
  exit 2
fi

cd "$PROJECT_ROOT"
docker compose up -d mysql

printf 'Waiting for MySQL to become ready'
ready=false
for _ in $(seq 1 60); do
  if docker compose exec -T mysql sh -c '
    MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqladmin \
      ping --host=127.0.0.1 --user=root --silent
  ' >/dev/null 2>&1; then
    ready=true
    break
  fi
  printf '.'
  sleep 2
done
printf '\n'

if [[ "$ready" != true ]]; then
  printf 'MySQL did not become ready. Check the service with: docker compose logs mysql\n' >&2
  exit 1
fi

mysql_user="$(docker compose exec -T mysql printenv MYSQL_USER | tr -d '\r\n')"
if [[ ! "$mysql_user" =~ ^[A-Za-z0-9_]+$ ]]; then
  printf 'MYSQL_USER must contain only letters, digits, or underscores.\n' >&2
  exit 1
fi

database_sql="CREATE DATABASE \`$target_database\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; GRANT ALL PRIVILEGES ON \`$target_database\`.* TO '$mysql_user'@'%';"
if ! docker compose exec -T mysql sh -c '
  MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql --user=root --execute="$1"
' sh "$database_sql"; then
  printf 'Could not create fresh database "%s". It may already exist.\n' "$target_database" >&2
  exit 1
fi

if ! docker compose exec -T mysql sh -c '
  MYSQL_PWD="$MYSQL_PASSWORD" exec mysql --user="$MYSQL_USER" "$1"
' sh "$target_database" < "$backup_file"; then
  printf 'Restore failed while importing "%s" into "%s". The new database may be incomplete.\n' "$backup_file" "$target_database" >&2
  exit 1
fi

printf 'Restored %s into fresh database "%s".\n' "$backup_file" "$target_database"
