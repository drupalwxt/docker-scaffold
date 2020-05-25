ARG BASE_IMAGE
FROM $BASE_IMAGE

COPY php.ini /usr/local/etc/php/php.ini

# Proper locale needed to use Postgres
RUN echo "en_US" > /usr/local/etc/locale.md

# Install language pack
RUN apk --no-cache add ca-certificates wget && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-bin-2.31-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-i18n-2.31-r0.apk && \
    apk add glibc-bin-2.31-r0.apk glibc-i18n-2.31-r0.apk glibc-2.31-r0.apk

# Iterate through all locale and install it
# Note that locale -a is not available in alpine linux, use `/usr/glibc-compat/bin/locale -a` instead
RUN cat /usr/local/etc/locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8

# Set the lang, you can also specify it as as environment variable through docker-compose.yml
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

## START CI

WORKDIR /var/www

# Install composer dependencies
# TODO: Determine if this is really needed
# RUN composer install --prefer-dist --no-interaction

RUN ln -s /var/www/vendor/bin/behat /usr/local/bin/behat; \
    ln -s /var/www/vendor/bin/phpcs /usr/local/bin/phpcs; \
    ln -s /var/www/vendor/bin/phpmd /usr/local/bin/phpmd; \
    ln -s /var/www/vendor/bin/phpunit /usr/local/bin/phpunit; \
    ln -s /var/www/vendor/bin/drupal /usr/local/bin/drupal

RUN phpcs --config-set installed_paths /var/www/vendor/drupal/coder/coder_sniffer

## END CI

# XDebug
RUN git clone https://github.com/xdebug/xdebug.git /tmp/xdebug; \
    mkdir -p /usr/src/php/ext; \
    mv /tmp/xdebug /usr/src/php/ext/; \
    docker-php-ext-install xdebug

RUN sed -i '1 a xdebug.remote_autostart=true' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    sed -i '1 a xdebug.remote_mode=req' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    sed -i '1 a xdebug.remote_handler=dbgp' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    sed -i '1 a xdebug.remote_connect_back=1 ' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    sed -i '1 a xdebug.remote_port=9000' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    sed -i '1 a xdebug.remote_host=127.0.0.1' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    sed -i '1 a xdebug.remote_enable=1' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    sed -i '1 a xdebug.idekey=phpstorm' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN php -r "opcache_reset();"

# Mac hack to get permissions to work.
# Set user 1000 and group staff to www-data.
# https://github.com/boot2docker/boot2docker/issues/581#issuecomment-114804894
RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
RUN apk add --update --no-cache shadow@community=4.7-r1; \
    addgroup staff; \
    usermod -u 1000 www-data; \
    usermod -G staff www-data

WORKDIR /var/www/html
