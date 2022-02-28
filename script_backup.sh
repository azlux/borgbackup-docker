#!/usr/bin/env bash

source /tmp/project_env.sh

if ! [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    MYSQL_PWD="$MYSQL_PASSWORD" mysqldump --all-databases --single-transaction -u "$MYSQL_USER" -h "$MYSQL_HOST" > /tmp/all_databases_mysql.sql
    borgbackup create --stats --compression lz4 "$BACKUP_PATH"::db_mysql_$(date +%Y-%m-%d_%H:%M) "/tmp/all_databases_mysql.sql"
    rm /tmp/all_databases_mysql.sql
fi

if ! [ -z "$POSTGRES_HOST" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    PGPASSWORD="$POSTGRES_PASSWORD" pg_dumpall -U "$POSTGRES_USER" -h "$POSTGRES_HOST" > /tmp/all_databases_pg.out
    borgbackup create --stats --compression lz4 "$BACKUP_PATH"::db_postgres_$(date +%Y-%m-%d_%H:%M) "/tmp/all_databases_pg.out"
    rm /tmp/all_databases_pg.out
fi

for d in $FOLDERS_TO_BACKUP_PATH/*; do
    if [ -d "$d" ]; then
        borgbackup create --stats --compression lz4 "$BACKUP_PATH"::$(echo ${d##*/})_$(date +%Y-%m-%d_%H:%M) "$d"
    fi
done

borgbackup prune -v --keep-within=10d --keep-weekly=4 --keep-monthly=6 "$BACKUP_PATH"

