#!/usr/bin/env bash

if [ "$1" == "bash" ] || [ "$1" == "sh" ]; then
    exec "${@}"
fi

if [ -z "$BORG_PASSPHRASE" ]; then
    echo "[ERR] BORG_PASSPHRASE env variable not set. Exiting"
    exit 1
fi

if [ -z "$FOLDERS_TO_BACKUP_PATH" ]; then
    echo "[ERR] FOLDERS_TO_BACKUP_PATH env variable not set. Exiting"
    exit 1
fi

if [ -z "$BACKUP_PATH" ]; then
    echo "[ERR] BACKUP_PATH env variable not set. Exiting"
    exit 1
fi

if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "[INFO] MYSQL not fully set, MYSQL Backup disable"
else
    echo "[INFO] MYSQL configurated, MYSQL backup enabled"
fi

if [ -z "$POSTGRES_HOST" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    echo "[INFO] POSTGRES not fully set, POSTGRES Backup disable"
else
    POSTGRES_CURRENT_VERSION=$(pg_dumpall --version | cut -f 3 -d ' ' | cut -f 1 -d '.')
    if [ -n "$POSTGRES_VERSION" ] && [ "$POSTGRES_VERSION" -ne "$POSTGRES_CURRENT_VERSION" ]; then
        echo "[INFO] Removing the default postgres client version $POSTGRES_CURRENT_VERSION provided by Debian $(lsb_release -cs)"
        apt-get -qq update && apt-get -qq remove -y postgresql-client*
        echo "[INFO] Installing the requested postgres client version $POSTGRES_VERSION"
        apt-get -qq install -y postgresql-client-${POSTGRES_VERSION}
        retVal=$?
        if [ $retVal -ne 0 ]; then
            echo "[ERR] An issue appear during the postgresql-client-${POSTGRES_VERSION} install"
            echo "[ERR] maybe this version isn't available for $(lsb_release -cs)"
            echo "[ERR] some 32bits CPU aren't supported by postgres repository (like armhf/armv7), so only the Debian stable version is available"
            echo "[ERR] Exiting !"
            exit 1
        fi
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
  

