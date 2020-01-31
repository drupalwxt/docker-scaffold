# https://github.com/docker-library/drupal/blob/master/8.8/fpm-alpine/Dockerfile
FROM drupal:8.8-fpm-alpine

ARG SSH_PRIVATE_KEY
ARG GIT_USERNAME
ARG GIT_PASSWORD

RUN apk --update add fcgi \
    && curl -o /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck
COPY docker/conf/php-fpm/status.conf /usr/local/etc/php-fpm.d/

HEALTHCHECK --interval=5s --timeout=10s --start-period=5s --retries=3 CMD [ "php-fpm-healthcheck" ]

# Install additional extensions
RUN apk --update add --no-cache bash=5.0.11-r1 \
                                git=2.24.1-r0 \
                                gzip=1.10-r0 \
                                mysql-client=10.4.12-r0 \
                                patch=2.7.6-r6 \
                                postgresql-client=12.1-r0 \
                                ssmtp=2.64-r14 \
                                zlib-dev=1.2.11-r3

COPY docker/conf/ssmtp.conf /etc/ssmtp/ssmtp.conf
RUN echo "hostname=drupalwxt.github.io" >> /etc/ssmtp/ssmtp.conf
RUN echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini
COPY docker/conf/php.ini /usr/local/etc/php/php.ini

# Install additional php extensions
RUN apk add --update --no-cache icu=64.2-r0 \
                                icu-libs=64.2-r0 \
                                libzip-dev=1.5.2-r0; \
    \
    apk add --no-cache --virtual .build-deps icu-dev=64.2-r0; \
    \
    docker-php-ext-configure zip \
        --with-zlib-dir=/usr; \
    \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        intl \
        zip; \
    \
    apk del .build-deps

# Composer recommended settings
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_VERSION 1.9.1
ENV COMPOSER_MEMORY_LIMIT -1
ENV COMPOSER_EXIT_ON_PATCH_FAILURE 1

# Check Composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer; \
    curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
    php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

# Install Composer
RUN php /tmp/composer-setup.php --no-ansi \
                                --install-dir=/usr/local/bin \
                                --filename=composer \
                                --version=${COMPOSER_VERSION}; \
    rm -rf /tmp/composer-setup.php

# Install Drupal WxT
RUN rm -f /var/www/composer.lock; \
    rm -rf /root/.composer
RUN rm -rf /var/www/*
COPY scripts/ScriptHandler.php /var/www/scripts/ScriptHandler.php
COPY composer.json /var/www/composer.json
COPY composer.lock /var/www/composer.lock
WORKDIR /var/www
RUN apk --update --no-cache add git openssh-client; \
    mkdir -p /root/.ssh; echo $SSH_PRIVATE_KEY | base64 -d > /root/.ssh/id_rsa; \
    chmod 700 /root/.ssh; chmod 600 /root/.ssh/id_rsa; \
    ssh-keyscan github.com > /root/.ssh/known_hosts; \
    composer global require "hirak/prestissimo:^0.3"; \
    composer install --prefer-dist \
                     --no-interaction && \
    rm -rf /root/.ssh && \
    apk del openssh-client

# Permissions
WORKDIR /var/www/html
RUN chown -R www-data:www-data sites/default

# See: https://github.com/docker/docker/issues/9299
RUN echo "export TERM=xterm" >> ~/.bashrc

# Drush
RUN ln -s /var/www/vendor/drush/drush/drush /usr/local/bin/drush

# Reset Cache
RUN php -r 'opcache_reset();'
