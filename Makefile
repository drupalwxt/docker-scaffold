include .env

NAME := $(or $(BASE_IMAGE),$(BASE_IMAGE),drupalwxt/site-wxt)
VERSION := $(or $(VERSION),$(VERSION),'latest')
PLATFORM := $(shell uname -s)

all: base

base:
	docker build -f docker/Dockerfile \
	    -t $(NAME):$(VERSION) \
	    --build-arg SSH_PRIVATE_KEY="$$(test -f $$HOME/.ssh/id_rsa && base64 $$HOME/.ssh/id_rsa)" \
	    --no-cache \
	    --build-arg http_proxy=$$HTTP_PROXY \
	    --build-arg HTTP_PROXY=$$HTTP_PROXY \
	    --build-arg https_proxy=$$HTTP_PROXY \
	    --build-arg HTTPS_PROXY=$$HTTP_PROXY \
	    --build-arg no_proxy=$$NO_PROXY \
	    --build-arg NO_PROXY=$$NO_PROXY \
	    --build-arg GIT_USERNAME=$(GIT_USERNAME) \
	    --build-arg GIT_PASSWORD=$(GIT_PASSWORD) .

behat:
	./docker/bin/behat -vv -c behat.yml --colors

build: all

clean: clean_composer

clean_composer:
	rm -rf html
	rm -rf vendor
	rm -f composer.lock
	composer clear-cache

clean_docker:
	rm -rf docker
	git clone --branch 9.x-postgres $(DOCKER_REPO) docker
	[ "$(shell docker images -q --filter "dangling=true")" = "" ] || docker rmi -f $(shell docker images -q --filter "dangling=true")
	[ "$(shell docker ps -a -q -f name=${DOCKER_NAME}_)" = "" ] || docker rm -f $(shell docker ps -a -q -f name=${DOCKER_NAME}_)
	[ "$(shell docker images -q -f reference=${DOCKER_IMAGE}_*)" = "" ] || docker rmi -f $(shell docker images -q -f reference=*${DOCKER_IMAGE}_*)
	[ "$(shell docker images -q -f reference=${NAME})" = "" ] || docker rmi -f $(shell docker images -q -f reference=${NAME})

clean_drupal: clean_composer composer_install docker_stop docker_start drupal_install

clean_site: clean_composer composer_install clean_docker base docker_build drupal_install
	./docker/bin/drush cr

composer_install:
	composer install

docker_build:
	docker-compose build --no-cache
	docker-compose up -d

docker_start:
	docker-compose up -d

docker_stop:
	docker-compose down

drupal_cs:
	mkdir -p html/core/
	cp docker/conf/phpcs.xml html/core/phpcs.xml
	cp docker/conf/phpunit.xml html/core/phpunit.xml

drupal_install:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-first-run $(DB_NAME)

drupal_init:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-init $(PROFILE_NAME)

drupal_export:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-export $(PROFILE_NAME) "${DATABASE_BACKUP}"

drupal_import:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-import wxt "${DATABASE_BACKUP}"

drupal_migrate:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-migrate

drupal_perm:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-perm $(PROFILE_NAME)

drush_archive:
	./docker/bin/drush archive-dump --destination="/var/www/files_private/drupal$$(date +%Y%m%d_%H%M%S).tgz" \
                                  --generator="Drupal"

env:
	eval $$(docker-machine env default)

export: drupal_export

import: drupal_init drupal_perm drupal_import

lint:
	./docker/bin/lint

# http://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

phpcs: drupal_cs
	./docker/bin/phpcs --config-set installed_paths /var/www/vendor/drupal/coder/coder_sniffer

	./docker/bin/phpcs --standard=/var/www/html/core/phpcs.xml \
	    --extensions=php,module,inc,install,test,profile,theme \
	    --report=full \
	    --colors \
	    --ignore=/var/www/html/profiles/$(PROFILE_NAME)/modules/custom/wxt_test \
	    --ignore=*.css \
	    --ignore=*.txt \
	    --ignore=*.md \
	    --ignore=/var/www/html/*/custom/*/*.info.yml \
	    /var/www/html/modules/contrib/wxt_library \
	    /var/www/html/themes/contrib/wxt_bootstrap \
	    /var/www/html/profiles/$(PROFILE_NAME)/modules/custom

	./docker/bin/phpcs --standard=/var/www/html/core/phpcs.xml \
	    --extensions=php,module,inc,install,test,profile,theme \
	    --report=full \
	    --colors \
	    --ignore=*.md \
	    -l \
	    /var/www/html/profiles/$(PROFILE_NAME)

phpunit:
	./docker/bin/phpunit --colors=always \
	    --testsuite=kernel \
	    --group $(PROFILE_NAME)

	./docker/bin/phpunit --colors=always \
	    --testsuite=unit \
	    --group $(PROFILE_NAME)

release: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make base'"; false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest

test: phpcs phpunit behat

up:
	docker-machine start default
	eval $$(docker-machine env default)
	docker-compose up -d

update: base
	git pull origin 8.x
	composer update
	docker-compose build --no-cache
	docker-compose up -d

.PHONY: \
	all \
	base \
	behat \
	build \
	clean \
	clean_composer \
	clean_docker \
	clean_site \
	composer_install \
	docker_build \
	drupal_cs \
	drupal_export \
	drupal_install \
	drupal_import \
	drupal_migrate \
	drush_archive \
	env \
	export \
	import \
	lint \
	list \
	phpcs \
	phpunit \
	release \
	tag_latest \
	test \
	up \
	update
