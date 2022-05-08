# https://github.com/docker-library/drupal/blob/master/9.2/php8.0/fpm-alpine3.15/Dockerfile
FROM drupal:9.2-fpm-alpine

ARG SSH_PRIVATE_KEY
ARG GIT_USERNAME
ARG GIT_PASSWORD

RUN apk --update add fcgi \
    && curl -o /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck
COPY docker/conf/php-fpm/status.conf /usr/local/etc/php-fpm.d/

HEALTHCHECK --interval=5s --timeout=10s --start-period=5s --retries=3 CMD [ "php-fpm-healthcheck" ]

# Install additional extensions
RUN apk --update add --no-cache bash \
                                git \
                                gzip \
                                mysql-client \
                                patch \
                                postgresql-client \
                                ssmtp \
                                zlib-dev

COPY docker/conf/ssmtp.conf /etc/ssmtp/ssmtp.conf
RUN echo "hostname=drupalwxt.github.io" >> /etc/ssmtp/ssmtp.conf
RUN echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini
COPY docker/conf/php.ini /usr/local/etc/php/php.ini

# Install additional php extensions
RUN apk add --update --no-cache autoconf \
                                icu \
                                icu-libs \
                                libzip-dev \
                                gcc \
                                g++ \
                                make \
                                libffi-dev \
                                openssl-dev; \
    \
    apk add --no-cache --virtual .build-deps icu-dev; \
    \
    docker-php-ext-configure zip \
        --with-zlib-dir=/usr; \
    \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        intl \
        zip; \
    \
    docker-php-source extract \
    && pecl install \
        mysqlnd_azure \
    && docker-php-ext-enable \
        mysqlnd_azure \
    && docker-php-source delete \
    && mkdir -p /etc/ssl/mysql \
    \
    apk del .build-deps

COPY docker/certs/BaltimoreCyberTrustRoot.crt.pem /etc/ssl/mysql/BaltimoreCyberTrustRoot.crt.pem

# Redis
ENV PHPREDIS_VERSION 5.3.6
RUN mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis

# Composer recommended settings
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_VERSION 2.0.6
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
    composer install --prefer-dist \
                     --ignore-platform-reqs \
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

# ------------------------
# SSH Server support
# Alpine Reference: https://docs.microsoft.com/en-us/azure/app-service/configure-custom-container?pivots=container-linux#enable-ssh
# This is a specfic feature of Azure Web Apps which has its own isolation and should not be used in any other scenario.
# ------------------------

# Install OpenSSH and set the password for root to "Docker!"
RUN apk add openssh \
     && echo "root:Docker!" | chpasswd

# Copy the sshd_config file to the /etc/ssh/ directory
COPY docker/conf/sshd/sshd_config /etc/ssh/

# Copy and configure the ssh_setup file
RUN mkdir -p /tmp
COPY docker/conf/sshd/ssh_setup.sh /tmp
RUN chmod +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null)

# Open port 2222 for SSH access
EXPOSE 80 2222
ENTRYPOINT ["docker/conf/sshd/sshd_init.sh"]
