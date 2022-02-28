FROM debian:bullseye-slim
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt install -y -q wget gnupg2 && \
    echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y borgbackup cron mariadb-client bash procps postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY cron_backup /etc/cron.d/backup
COPY script_backup.sh /script_backup.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /script_backup.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["cron", "-f"]
