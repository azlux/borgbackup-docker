#!/usr/bin/env bash
set -u

log() {
    echo "$(date --iso-8601=seconds) $*"
}

BACKUP_ERRORS=0

handle_borg_rc() {
    local rc="$1"
    local operation="$2"

    case "$rc" in
        0)
            ;;
        1)
            log "WARNING: ${operation} completed with warnings"
            ;;
        *)
            log "ERROR: ${operation} failed (rc=${rc})"
            BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
            ;;
    esac
}

backup_archive() {
    local archive_name="$1"
    local sources="$2"

    borgbackup create --stats --compression lz4 "$BACKUP_PATH"::"$archive_name" "$sources"
    handle_borg_rc $? "Backup ${archive_name}"
}

prune_archive() {
    local pattern="$1"

    borgbackup prune --stats -v --glob-archives="$pattern" --keep-within="$BORG_KEEP_WITHIN" --keep-weekly="$BORG_KEEP_WEEKLY" --keep-monthly="$BORG_KEEP_MONTHLY" "$BACKUP_PATH"
    handle_borg_rc $? "Prune ${pattern}"
}

# Chargement variables environnement
log "STARTING BACKUP JOB"

[ -f /tmp/project_env.sh ] && source /tmp/project_env.sh

KUMA_PUSH_URL="${KUMA_PUSH_URL:-}"

#########
# MYSQL #
#########
if [ -n "${MYSQL_HOST:-}" ] && [ -n "${MYSQL_USER:-}" ] && [ -n "${MYSQL_PASSWORD:-}" ]; then
    log "STARTING BACKUP MYSQL"
    MYSQL_DUMP_FILE="/tmp/all_databases_mysql.sql"
    MYSQL_PWD="$MYSQL_PASSWORD" mysqldump --all-databases --single-transaction -u "$MYSQL_USER" -h "$MYSQL_HOST" > "$MYSQL_DUMP_FILE"

    RC=$?
    if [ $RC -ne 0 ]; then
        log "ERROR: MySQL dump failed (rc=$RC)"
        BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
    else
        backup_archive "db_mysql_$(date +%Y-%m-%d_%H:%M)" "$MYSQL_DUMP_FILE"
    fi
    rm -f "$MYSQL_DUMP_FILE"

    log "STARTING PRUNE MYSQL"
    prune_archive "db_mysql_*"
fi

############
# POSTGRES #
############
if [ -n "${POSTGRES_HOST:-}" ] && [ -n "${POSTGRES_USER:-}" ] && [ -n "${POSTGRES_PASSWORD:-}" ]; then
    log "STARTING BACKUP POSTGRES"
    PG_DUMP_FILE="/tmp/all_databases_pg.out"
    PGPASSWORD="$POSTGRES_PASSWORD" pg_dumpall -U "$POSTGRES_USER" -h "$POSTGRES_HOST" > "$PG_DUMP_FILE"

    RC=$?
    if [ $RC -ne 0 ]; then
        log "ERROR: PostgreSQL dump failed (rc=$RC)"
        BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
    else
        backup_archive "db_postgres_$(date +%Y-%m-%d_%H:%M)" "$PG_DUMP_FILE"
    fi
    rm -f "$PG_DUMP_FILE"

    log "STARTING PRUNE POSTGRES"
    prune_archive "db_postgres_*"
fi

###########
# FOLDERS #
###########
for d in "$FOLDERS_TO_BACKUP_PATH"/*; do
    [ ! -d "$d" ] && continue
    folder_name="${d##*/}"
    log "STARTING BACKUP FOLDER $d"
    backup_archive "${folder_name}_$(date +%Y-%m-%d_%H:%M)" "$d"

    log "STARTING PRUNE FOLDER $d"
    prune_archive "${folder_name}_*"
done

###########
# COMPACT #
###########

log "COMPACTING BACKUP"

borgbackup compact "$BACKUP_PATH"
handle_borg_rc $? "Compact repository"

########
# KUMA #
########
if [ -n "$KUMA_PUSH_URL" ]; then
    log "SEND MONITORING NOTIFICATION"
    if [ "$BACKUP_ERRORS" -eq 0 ]; then
        curl -fsS -m 10 --retry 3 "${KUMA_PUSH_URL}?status=up&msg=OK" > /dev/null 2>&1 || true
    else
        curl -fsS -m 10 --retry 3 "${KUMA_PUSH_URL}?status=down&msg=failed%20with%20${BACKUP_ERRORS}%20errors" > /dev/null 2>&1 || true
    fi
fi

log "END BACKUP JOB WITH ${BACKUP_ERRORS} ERRORS"

exit "$BACKUP_ERRORS"
