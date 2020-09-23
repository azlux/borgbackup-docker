FROM debian:buster-slim
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y borgbackup cron mariadb-client bash procps && \
    rm -rf /var/lib/apt/lists/*

COPY cron_backup /etc/cron.d/backup
COPY script_backup.sh /script_backup.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /script_backup.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["cron", "-f"]
