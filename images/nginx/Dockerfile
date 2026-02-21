ARG BASE_IMAGE
FROM $BASE_IMAGE as src

FROM nginx:alpine

# Make writable for random UID (OpenShift) and normal nginx (K8s)
RUN chgrp -R 0 /var/cache/nginx /var/run /var/log/nginx && \
    chmod -R g+rwX /var/cache/nginx /var/run /var/log/nginx

COPY --from=src /var/www/html /var/www/html
