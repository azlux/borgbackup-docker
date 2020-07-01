# borgbackup-docker
backup folders find in environment variables

[![Build Status](https://ci.azlux.fr/api/badges/azlux/borgbackup-docker/status.svg)](https://ci.azlux.fr/azlux/borgbackup-docker)


If MySQL values are givent, mysqldumpo will be also done and added to the backup.

Docker Hub link : https://hub.docker.com/r/azlux/borgbackup

## Environnements variables:

### Mandatory:
- `BORG_PASSPHRASE` - borgbackup passphrase
- `FOLDERS_TO_BACKUP_PATH` - folder path where you put the Volumes to backup
- `BACKUP_PATH` - Backup Volume path

### Optionnal
- `MYSQL_USER` - MySQL User (with all table read access)
- `MYSQL_PASSWORD` - MySQL Password
- `MYSQL_HOST` - IP or name of the MysQL Host


## Docker-compose example:
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
        - /first/path/on/host:/folder_to_backup/data2
        - /backup/path/on/host:/backup
    tmpfs: /tmp
```
