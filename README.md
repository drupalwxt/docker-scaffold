Docker Scaffold for Drupal
==========================

Provides an barebones, fast, and lightweight local / CI docker environment to work with [Drupal WxT][wxt].

## Setup

In order to use this project your base Composer Project should have the following:

* A `composer.json` file at the root directory
* A `.env` file at the root directory with your specific values
* Symlinks at the root directory to both the `Makefile` and the specific `docker.yml` files you may need
* This repository cloned into the root directory with the name `docker`

> Note: To see a working example we take a look at the [Composer Project for Drupal WxT][site-wxt]


[composer]:                     https://getcomposer.org
[docker-scaffold]:              https://github.com/drupalwxt/docker-scaffold.git
[site-wxt]:                     https://github.com/drupalwxt/site-wxt
[wxt]:                          https://github.com/drupalwxt/wxt