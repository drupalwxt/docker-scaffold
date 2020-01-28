ARG BASE_IMAGE
FROM $BASE_IMAGE as src

FROM nginx:alpine

COPY --from=src /var/www/html /var/www/html
