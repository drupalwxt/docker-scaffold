Docker Scaffold for Drupal
==========================

Provides an barebones, fast, and lightweight local / CI docker environment to work with [Drupal][wxt].

## Pre-Requisites

You need to be using Docker Compose V2 and ensure the version >= v2.15.0.

## Setup

Installation is fairly straight forward as long as you are managing your site dependencies with Composer.

```sh
git clone https://github.com/drupalwxt/docker-scaffold.git docker
```

> **Note**: This command must be run at the root of the Composer Project where the `composer.json` file exists.

## Documentation

For more information please consult the documentation:

* https://drupalwxt.github.io/en/docs/environment/containers/

[composer]:                     https://getcomposer.org
[docker-scaffold]:              https://github.com/drupalwxt/docker-scaffold.git
[site-wxt]:                     https://github.com/drupalwxt/site-wxt
[wxt]:                          https://github.com/drupalwxt/wxt
