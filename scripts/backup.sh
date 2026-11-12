#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups"

mkdir -p "$BACKUP_DIR"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_file="$BACKUP_DIR/mysql_${timestamp}.sql"
suffix=1
while [[ -e "$backup_file" ]]; do
  backup_file="$BACKUP_DIR/mysql_${timestamp}_${suffix}.sql"
  ((suffix += 1))
done

temporary_file="$(mktemp "$BACKUP_DIR/.mysql_backup.XXXXXX")"
trap 'rm -f -- "$temporary_file"' EXIT

cd "$PROJECT_ROOT"
if ! docker compose exec -T mysql sh -c '
  MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqldump \
    --user=root \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --no-tablespaces \
    "$MYSQL_DATABASE"
' > "$temporary_file"; then
  printf 'Database backup failed. Ensure the MySQL service is running and healthy.\n' >&2
  exit 1
fi

if [[ ! -s "$temporary_file" ]]; then
  printf 'Database backup failed: mysqldump produced an empty file.\n' >&2
  exit 1
fi

mv -- "$temporary_file" "$backup_file"
printf 'Database backup created: %s\n' "$backup_file"
