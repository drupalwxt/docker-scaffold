# https://github.com/drupalwxt/docker-scaffold/blob/9.3.x-appsvc/Dockerfile
ARG BASE_IMAGE
FROM $BASE_IMAGE as src

# Configure supervisor
RUN apk add --no-cache supervisor
RUN mkdir -p /etc/supervisor.d/
RUN mkdir -p /var/log/supervisord/
COPY conf/supervisord.ini /etc/supervisor.d/supervisord.ini

# Configure nginx
RUN apk add --no-cache nginx
RUN mkdir -p /etc/nginx

# Configure varnish
RUN apk add --no-cache nginx
RUN mkdir -p /etc/nginx

# Configure cron
COPY tasks/ /etc/periodic/
RUN chmod -R +x /etc/periodic/

# Open port 2222 for SSH access
EXPOSE 80 2222
ENTRYPOINT ["/etc/ssh/sshd_init.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
