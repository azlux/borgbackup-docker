FROM debian:trixie-slim
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt install -y -q curl ca-certificates gnupg2 lsb-release && \
    echo "deb [signed-by=/usr/share/keyrings/apt.postgresql.org.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor --yes -o /usr/share/keyrings/apt.postgresql.org.gpg && \
    apt-get update && \
    apt-get install -y borgbackup cron mariadb-client bash procps postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY cron_backup /etc/cron.d/backup
COPY script_backup.sh /script_backup.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /script_backup.sh && \
    chmod +x /entrypoint.sh

# Add default KEEP values if unset
ENV BORG_KEEP_WITHIN="14d"
ENV BORG_KEEP_WEEKLY=8
ENV BORG_KEEP_MONTHLY=6

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["cron", "-f"]
