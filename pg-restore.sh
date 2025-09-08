#!/bin/bash
#$1 - database name
#$2 - backup file name

export $(grep -v '^#' .env | xargs)

# Check if the database exists, create if not
DB_EXISTS=$(PGPASSWORD=$POSTGRES__PASSWORD psql -U $POSTGRES__USERNAME -h localhost -p 5432 -tAc "SELECT 1 FROM pg_database WHERE datname='$1'")
if [ "$DB_EXISTS" != "1" ]; then
  echo "Database $1 does not exist. Creating..."
  PGPASSWORD=$POSTGRES__PASSWORD createdb -U $POSTGRES__USERNAME -h localhost -p 5432 $1
fi

PGPASSWORD=$POSTGRES__PASSWORD pg_restore -U $POSTGRES__USERNAME  -d $1 -h localhost -p 5432 -v -c -O -Fc $2
