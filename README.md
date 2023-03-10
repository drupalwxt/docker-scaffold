Docker Scaffold for Drupal
==========================

Provides an barebones, fast, and lightweight local / CI docker environment to work with [Drupal][wxt].

## Pre-Requisites

You need to be using Docker Compose V2 and ensure the version >= v2.15.0.

## Setup

Installation is relatively straight forward as long as you are managing your site dependencies with Composer.

All of these commands must be run at the root of the Composer Project where the `composer.json` file exists.

Clone the docker-scaffold repository:

```sh
git clone https://github.com/drupalwxt/docker-scaffold.git docker
```

> **Note**: The `docker` folder should be added to your `.gitignore` file.

Create the necessary symlinks:

```sh
ln -s docker/docker-compose.base.yml docker-compose.base.yml
ln -s docker/docker-compose.ci.yml docker-compose.ci.yml
ln -sf docker/docker-compose.yml docker-compose.yml
```

Create and adjust the following Makefile:

```sh
include .env
NAME := $(or $(BASE_IMAGE),$(BASE_IMAGE),drupalwxt/site-wxt)
VERSION := $(or $(VERSION),$(VERSION),'latest')
PLATFORM := $(shell uname -s)
$(eval GIT_USERNAME := $(if $(GIT_USERNAME),$(GIT_USERNAME),gitlab-ci-token))
$(eval GIT_PASSWORD := $(if $(GIT_PASSWORD),$(GIT_PASSWORD),$(CI_JOB_TOKEN)))
DOCKER_REPO := https://github.com/drupalwxt/docker-scaffold.git
GET_DOCKER := $(shell [ -d docker ] || git clone $(DOCKER_REPO) docker)
include docker/Makefile
```

## Example

You can see the docker-scaffold in use in the `site-wxt` repository:

* https://github.com/drupalwxt/site-wxt

## Documentation

For more information please consult the documentation:

* https://drupalwxt.github.io/en/docs/environment/containers/

[composer]:                     https://getcomposer.org
[docker-scaffold]:              https://github.com/drupalwxt/docker-scaffold.git
[site-wxt]:                     https://github.com/drupalwxt/site-wxt
[wxt]:                          https://github.com/drupalwxt/wxt
