Docker Scaffold for Drupal
==========================

Provides an barebones, fast, and lightweight local / CI docker environment to work with [Drupal WxT][wxt].

## Setup

```sh
git clone https://github.com/drupalwxt/docker-scaffold.git docker
```

## Composer install

```sh
export COMPOSER_MEMORY_LIMIT=-1 && composer install
```

## MacOSX Specifics (https://wiki.zacharyseguin.ca/books/development/page/mutagen-sync)

```sh
export VOLUME=mutagen-cache
export NAME=site-wxt
docker volume create $VOLUME
docker container create --name $VOLUME -v $VOLUME:/volumes/$VOLUME mutagenio/sidecar
docker start $VOLUME
mutagen sync create --name $NAME --sync-mode=two-way-resolved --default-file-mode-beta 0666 --default-directory-mode-beta 0777  $(pwd) docker://mutagen-cache/volumes/mutagen-cache
mutagen sync monitor
```

## Make our base docker image

```sh
make build
```

## Bring up the dev stack

```sh
docker-compose -f docker-compose.yml up -d

# Mutagen installs
# ln -s docker/docker-compose-mutagen.yml docker-compose-mutagen.yml
# docker-compose -f docker-compose-mutagen.yml up -d

```

## Install Drupal

```sh
make drupal_install

## Development configuration
./docker/bin/drush config-set system.performance js.preprocess 0 -y && \
./docker/bin/drush config-set system.performance css.preprocess 0 -y && \
./docker/bin/drush php-eval 'node_access_rebuild();' && \
./docker/bin/drush config-set wxt_library.settings wxt.theme theme-gcweb -y && \
./docker/bin/drush cr

## Migrate default content
./docker/bin/drush migrate:import --group wxt --tag 'Core' && \
./docker/bin/drush migrate:import --group gcweb --tag 'Core' && \
./docker/bin/drush migrate:import --group gcweb --tag 'Menu'
```

## XDebug

If you wish to use XDebug in your development environment you can simply uncomment the lines.

> Note: This significantly slows down the Drupal installation.

[composer]:                     https://getcomposer.org
[docker-scaffold]:              https://github.com/drupalwxt/docker-scaffold.git
[site-wxt]:                     https://github.com/drupalwxt/site-wxt
[wxt]:                          https://github.com/drupalwxt/wxt
