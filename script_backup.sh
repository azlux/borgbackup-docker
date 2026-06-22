#!/usr/bin/env bash
echo $(date --iso-8601=seconds) STARTING BACKUP JOB
test -f /tmp/project_env.sh && source /tmp/project_env.sh

# Monitoring KUMA with the Push monitor
KUMA_PUSH_URL="${KUMA_PUSH_URL}"
BACKUP_ERRORS=0

if ! ([ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]); then
    echo $(date --iso-8601=seconds) STARTING BACKUP MYSQL
    MYSQL_PWD="$MYSQL_PASSWORD" mysqldump --all-databases --single-transaction -u "$MYSQL_USER" -h "$MYSQL_HOST" > /tmp/all_databases_mysql.sql
    RC=$?
    if [ $RC -ne 0 ];then
        BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
    else
        borgbackup create --stats --compression lz4 "$BACKUP_PATH"::db_mysql_$(date +%Y-%m-%d_%H:%M) "/tmp/all_databases_mysql.sql"
        RC=$?
        [ $RC -ne 0 ] && BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
    fi

    rm /tmp/all_databases_mysql.sql
    echo $(date --iso-8601=seconds) STARTING PRUNE MYSQL
    borgbackup prune --stats -v --glob-archives='db_mysql_*' --keep-within="$BORG_KEEP_WITHIN" --keep-weekly="$BORG_KEEP_WEEKLY" --keep-monthly="$BORG_KEEP_MONTHLY" "$BACKUP_PATH"
    RC=$?
    [ $RC -ne 0 ] && BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
fi

if ! ([ -z "$POSTGRES_HOST" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]); then
    echo $(date --iso-8601=seconds) STARTING BACKUP POSTGRES
    PGPASSWORD="$POSTGRES_PASSWORD" pg_dumpall -U "$POSTGRES_USER" -h "$POSTGRES_HOST" > /tmp/all_databases_pg.out
    RC=$?
    if [ $RC -ne 0 ];then
        BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
    else
        borgbackup create --stats --compression lz4 "$BACKUP_PATH"::db_postgres_$(date +%Y-%m-%d_%H:%M) "/tmp/all_databases_pg.out"
        RC=$?
        [ $RC -ne 0 ] && BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
    fi

    rm /tmp/all_databases_pg.out
    echo $(date --iso-8601=seconds) STARTING PRUNE POSTGRES
    borgbackup prune --stats -v --glob-archives='db_postgres_*' --keep-within="$BORG_KEEP_WITHIN" --keep-weekly="$BORG_KEEP_WEEKLY" --keep-monthly="$BORG_KEEP_MONTHLY" "$BACKUP_PATH"
    RC=$?
    [ $RC -ne 0 ] && BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
fi

for d in "$FOLDERS_TO_BACKUP_PATH"/*; do
    if [ -d "$d" ]; then
        echo $(date --iso-8601=seconds) STARTING BACKUP FOLDER "$d"
        borgbackup create --stats --compression lz4 "$BACKUP_PATH"::${d##*/}_$(date +%Y-%m-%d_%H:%M) "$d"
	RC=$?
        [ $RC -ne 0 ] && BACKUP_ERRORS=$((BACKUP_ERRORS + 1))

        echo $(date --iso-8601=seconds) STARTING PRUNE FOLDER "$d"
        borgbackup prune --stats -v --glob-archives="${d##*/}_*" --keep-within="$BORG_KEEP_WITHIN" --keep-weekly="$BORG_KEEP_WEEKLY" --keep-monthly="$BORG_KEEP_MONTHLY" "$BACKUP_PATH"
	RC=$?
        [ $RC -ne 0 ] && BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
    fi
done

echo $(date --iso-8601=seconds) COMPACTING BACKUP
borgbackup compact "$BACKUP_PATH"
RC=$?
[ $RC -ne 0 ] && BACKUP_ERRORS=$((BACKUP_ERRORS + 1))

if [ -n "$KUMA_PUSH_URL" ]; then
    echo $(date --iso-8601=seconds) SEND MONITORING NOTIFICATION
    if [ "$BACKUP_ERRORS" -eq 0 ]; then
        curl -fsS -m 10 --retry 3 "${KUMA_PUSH_URL}?status=up&msg=OK">/dev/null 2>&1 || true
    else
        curl -fsS -m 10 --retry 3 "${KUMA_PUSH_URL}?status=down&msg=failed%20with%20${BACKUP_ERRORS}%20errors">/dev/null 2>&1 || true
    fi
fi

echo $(date --iso-8601=seconds) END BACKUP JOB WITH ${BACKUP_ERRORS} ERRORS
