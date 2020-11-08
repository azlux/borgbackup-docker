# borgbackup-docker
Backup folders from environment variables with [BorgBackup tool](https://www.borgbackup.org/).

[![Build Status](https://ci.azlux.fr/api/badges/azlux/borgbackup-docker/status.svg)](https://ci.azlux.fr/azlux/borgbackup-docker)

I've create this image to have :
 - Simple to use backup
 - Easy management with  mount and cron (to avoid cron task on the host).
 - Easy setup with environnement variables
 - MySQL backup included
 - All backups encrypted

Feel free to improve the code on the github with pull requests and questions.

Docker Hub link : https://hub.docker.com/r/azlux/borgbackup

## Environnements variables:

### Mandatory:
- `BORG_PASSPHRASE` - borgbackup passphrase
- `FOLDERS_TO_BACKUP_PATH` - folder path where you put the Volumes to backup
- `BACKUP_PATH` - Backup Volume path

### Optionnal
If MySQL values are givent, mysqldump will be executed and added to the backup.
- `MYSQL_USER` - MySQL User (with all table read access)
- `MYSQL_PASSWORD` - MySQL Password
- `MYSQL_HOST` - IP or name of the MysQL Host
- `BACKUP_CRON`- Custom CRON time (`0 3 * * *` :every day at 3AM by default)

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
