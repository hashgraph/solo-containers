FROM rclone/rclone:1.69.1 as rclone

FROM ubuntu:noble-20250127

ARG UNAME=hedera
ARG UID=2000
ARG GID=2000
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME

COPY --from=rclone /usr/local/bin/rclone /bin/rclone

RUN apt-get update && \
  apt-get -y install \
    cron \
    ca-certificates \
    jq

# Create Application Folders
RUN mkdir -p "/app"

COPY cron /etc/cron.d/backup
ADD backup.sh /app/
ADD entrypoint.sh /app/
RUN chmod ugo+x /app/backup.sh /app/entrypoint.sh

COPY rclone.conf /root/.config/rclone/rclone.conf
COPY rclone.conf /home/hedera/.config/rclone/rclone.conf

ENTRYPOINT ["bash", "-c", "./app/entrypoint.sh"]

# Define Application Environment Variables
ENV RCLONE_CONFIG_BACKUPS_TYPE="s3"
ENV RCLONE_CONFIG_BACKUPS_PROVIDER="GCS"
ENV RCLONE_CONFIG_BACKUPS_REGION="us-central1"
ENV RCLONE_CONFIG_BACKUPS_ENDPOINT="https://storage.googleapis.com"
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
