FROM rclone/rclone:1.69.1 as rclone

FROM ubuntu:18.04

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

COPY cron /etc/cron.d/backup
ADD backup.sh /
ADD entrypoint.sh /
RUN chmod ugo+x /backup.sh /entrypoint.sh

COPY rclone.conf /root/.config/rclone/rclone.conf
COPY rclone.conf /home/hedera/.config/rclone/rclone.conf

ENTRYPOINT ["bash", "-c", "./entrypoint.sh"]
