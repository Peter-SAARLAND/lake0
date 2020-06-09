FROM alpine:latest as rclone

# # Get rclone executable
ADD https://downloads.rclone.org/rclone-current-linux-amd64.zip /
RUN unzip rclone-current-linux-amd64.zip && mv rclone-*-linux-amd64/rclone /bin/rclone && chmod +x /bin/rclone

FROM restic/restic:0.9.6

# # install mailx
RUN apk add --update --no-cache heirloom-mailx bash

COPY --from=rclone /bin/rclone /bin/rclone

RUN \
    mkdir -p /mnt/restic /var/spool/cron/crontabs /var/log; \
    touch /var/log/cron.log; \
    mkdir -p ${ENVIRONMENT_DIR} /root/.ssh /lake0;

ENV ENVIRONMENT_DIR=/root/.if0/.environments/zero

ENV RESTIC_REPOSITORY=/mnt/restic
ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""
ENV NFS_TARGET=""
ENV BACKUP_CRON="0 */6 * * *"
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""
ENV MAILX_ARGS=""

COPY backup.sh /bin/backup

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN echo 'export PS1="[\$IF0_ENVIRONMENT] \W # "' >> /root/.bashrc \
    && chmod +x /bin/backup \
    && chmod +x /docker-entrypoint.sh

WORKDIR "/"

COPY . .

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["tail","-fn0","/var/log/cron.log"]