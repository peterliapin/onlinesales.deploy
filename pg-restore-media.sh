#!/bin/bash
#$1 - database name
#$2 - backup file name

export $(grep -v '^#' .env | xargs)

PGPASSWORD=$POSTGRES__PASSWORD pg_restore -U $POSTGRES__USERNAME  -d $1 -h localhost -p 5432 -v -c -O -Fc -t media $2
