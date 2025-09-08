#!/bin/bash
# Usage: ./pg-backup.sh <database_name> [--exclude-user-tables]
# Options:
#   --exclude-user-tables    Exclude user-related tables from backup

export $(grep -v '^#' .env | xargs)


# Check if database name is provided
DB_NAME="$1"
if [ -z "$DB_NAME" ]; then
  echo "Error: Database name not provided." >&2
  echo "Usage: $0 <database_name> [--exclude-user-tables]" >&2
  exit 1
fi

EXCLUDE_USER_TABLES="$2"
BACKUP_NAME="${DB_NAME}-backup-$(date '+%Y-%m-%d-%H-%M').sql"

# Execute the backup with conditional exclusions
if [ "$EXCLUDE_USER_TABLES" = "--exclude-user-tables" ]; then
  echo "Excluding user-related tables from backup..." >&2
  echo "DEBUG: Running pg_dump with user table exclusions" >&2
  PGPASSWORD="$POSTGRES__PASSWORD" pg_dump -U "$POSTGRES__USERNAME" -d "$DB_NAME" -h localhost -p 5432 -Fc -x \
    --exclude-table=users \
    --exclude-table=user_claims \
    --exclude-table=user_logins \
    --exclude-table=user_roles \
    --exclude-table=user_tokens \
    --exclude-table=setting \
    --exclude-table=roles \
    --exclude-table=role_claims \
    > "$BACKUP_NAME"
else
  echo "DEBUG: Running pg_dump without exclusions" >&2
  PGPASSWORD="$POSTGRES__PASSWORD" pg_dump -U "$POSTGRES__USERNAME" -d "$DB_NAME" -h localhost -p 5432 -Fc -x > "$BACKUP_NAME"
fi