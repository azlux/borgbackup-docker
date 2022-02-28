#!/usr/bin/env bash

if [ -z "$BORG_PASSPHRASE" ]; then
    echo "BORG_PASSPHRASE env variable not set. Exiting"
    exit 1
fi

if [ -z "$FOLDERS_TO_BACKUP_PATH" ]; then
    echo "FOLDERS_TO_BACKUP_PATH env variable not set. Exiting"
    exit 1
fi

if [ -z "$BACKUP_PATH" ]; then
    echo "BACKUP_PATH env variable not set. Exiting"
    exit 1
fi

if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "MYSQL not fully set, MYSQL Backup disable"
else
    echo "MYSQL configurated, MYSQL backup enabled"
fi

if [ -z "$POSTGRES_HOST" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    echo "POSTGRES not fully set, POSTGRES Backup disable"
else
    if [ -n "$POSTGRES_VERSION" ] && [ "$POSTGRES_VERSION" -gt 9 ]; then
        apt-get -qq update && apt-get -qq remove -y postgresql-client* && apt-get -qq install -y postgresql-client-${POSTGRES_VERSION}
    fi
    echo "POSTGRES configurated, POSTGRES backup enabled"
fi

if [ ! -f "$BACKUP_PATH"/config ]; then
    borgbackup init --encryption=repokey "$BACKUP_PATH"
fi

if [ -n "$BACKUP_CRON" ]; then
    sed -i "s/0 3 \* \* \*/$BACKUP_CRON/" /etc/cron.d/backup
fi

# Save env variable for the cron
printenv | sed 's/^\(.*\)$/export \1/g' > /tmp/project_env.sh

if [ -n "$ONESHOT" ] && [ "$ONESHOT" == "true" ]; then
    /script_backup.sh > /proc/1/fd/1 2>/proc/1/fd/2
else
    exec "$@"
fi
  

