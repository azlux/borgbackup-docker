# borgbackup-docker
Backup folders from environment variables with [BorgBackup tool](https://www.borgbackup.org/).

Build every week for the base image update, and, of course, at every commit : [![Build Status](https://ci.azlux.fr/api/badges/azlux/borgbackup-docker/status.svg)](https://ci.azlux.fr/azlux/borgbackup-docker)

I've create this image to have :
 - Simple to use backup tool (by borgbackup)
 - Easy management with folder with few mount
 - Easy to run with internal cron (to avoid cron task on the host), optional if you have you own task manager (see ONESHOT variable).
 - Easy setup with environnement variables
 - MySQL backup included
 - Postgres backup included
 - All backups encrypted (by borgbackup)

Feel free to improve the code on the github with pull requests and questions.

Docker Hub link : https://hub.docker.com/r/azlux/borgbackup

## Environnements variables:

### Mandatory:
- `BORG_PASSPHRASE` - borgbackup passphrase
- `FOLDERS_TO_BACKUP_PATH` - folder path where you put the Volumes to backup
- `BACKUP_PATH` - Backup Volume path

### Optionnal
If MySQL or Postgres values are given, mysqldump and/or pg_dumpall will be executed and added to the backup.
- `MYSQL_USER` - MySQL User (with all table read access)
- `MYSQL_PASSWORD` - MySQL Password
- `MYSQL_HOST` - IP or name of the MysQL Host
- `POSTGRES_USER` - POSTGRES User (with all table read access)
- `POSTGRES_PASSWORD` - POSTGRES Password
- `POSTGRES_HOST` - IP or name of the POSTGRES Host
- `POSTGRES_VERSION` - Version of the postgres database if different from bookworm version
- `BACKUP_CRON` - Custom CRON time (`0 3 * * *` :every day at 3AM by default)
- `ONESHOT` - (true/false) Run the backup without cron (usefull if you have eternal scheduler) - False by default

## Docker-compose v2 example:
```
backup:
    image: azlux/borgbackup
    container_name: backup
    hostname: backup
    restart: on-failure
    environment:
        BORG_PASSPHRASE: ${BORG_PASSPHRASE}
        FOLDERS_TO_BACKUP_PATH: /folder_to_backup
        BACKUP_PATH: /backup
        MYSQL_USER: root
        MYSQL_PASSWORD: ${MARIADB_MYSQL_ROOT_PASSWORD}
        MYSQL_HOST: mariadb
    volumes:
        - /first/path/on/host:/folder_to_backup/data1
        - /second/path/on/host:/folder_to_backup/data2
        - ...
        - /backup/path/on/host:/backup
    tmpfs: /tmp
```
## Why Debian
Many people ask me for alpine image. If you want one, don't take my image.

After many years on docker, Alpine is the main source of my problems encountered.
Maybe, one day they will have a stable DNS support (no reproductible issues took me so many hours to debug).
