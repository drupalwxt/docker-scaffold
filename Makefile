NAME := $(or $(BASE_IMAGE),$(BASE_IMAGE),drupalwxt/site-wxt)
VERSION := $(or $(VERSION),$(VERSION),'latest')
PLATFORM := $(shell uname -s)

all: base

build: all

behat:
	./docker/bin/behat -c behat.yml --colors --verbose

clean:
	rm -rf {html,vendor}
	rm -f composer.lock
	composer clear-cache

clean_docker:
	docker rm $$(docker ps --all -q -f status=exited)

drupal_cs:
	mkdir -p html/core/
	cp docker/conf/phpcs.xml html/core/phpcs.xml
	cp docker/conf/phpunit.xml html/core/phpunit.xml

base:
	$(eval GIT_USERNAME := $(if $(GIT_USERNAME),$(GIT_USERNAME),gitlab-ci-token))
	$(eval GIT_PASSWORD := $(if $(GIT_PASSWORD),$(GIT_PASSWORD),$(CI_JOB_TOKEN)))
	docker build -f docker/Dockerfile \
               -t $(NAME):$(VERSION) \
               --no-cache \
               --build-arg SSH_PRIVATE_KEY="$$(test -f $$HOME/.ssh/id_rsa && base64 $$HOME/.ssh/id_rsa)" \
               --build-arg http_proxy=$$HTTP_PROXY \
               --build-arg HTTP_PROXY=$$HTTP_PROXY \
               --build-arg https_proxy=$$HTTP_PROXY \
               --build-arg HTTPS_PROXY=$$HTTP_PROXY \
               --build-arg GIT_USERNAME=$(GIT_USERNAME) \
               --build-arg GIT_PASSWORD=$(GIT_PASSWORD) .

drupal_install:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-first-run wxt

drupal_init:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-init wxt

drupal_export:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-export wxt "${DATABASE_BACKUP}"

drupal_import:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-import wxt "${DATABASE_BACKUP}"

drupal_migrate:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-migrate

drupal_perm:
	docker-compose exec -T cli bash /var/www/docker/bin/cli drupal-perm wxt

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
              --ignore=/var/www/html/profiles/wxt/modules/custom/wxt_test \
              --ignore=/var/www/html/modules/custom/wxt_library \
              --ignore=*.css \
              --ignore=*.md \
              --ignore=/var/www/html/*/custom/*/*.info.yml \
              /var/www/html/modules/custom \
              /var/www/html/themes/custom \
              /var/www/html/profiles/wxt/modules/custom

	./docker/bin/phpcs --standard=/var/www/html/core/phpcs.xml \
              --extensions=php,module,inc,install,test,profile,theme \
              --report=full \
              --colors \
              --ignore=*.md \
              -l \
              /var/www/html/profiles/wxt

phpunit:
	./docker/bin/phpunit --colors=always \
                --testsuite=kernel \
                --group wxt

	./docker/bin/phpunit --colors=always \
                --testsuite=unit \
                --group wxt

test: lint behat

up:
	docker-machine start default
	eval $$(docker-machine env default)
	docker-compose up -d

update: base
	git pull origin 8.x
	composer update
	docker-compose build --no-cache
	docker-compose up -d

release: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest

.PHONY: \
	all \
	base \
	behat \
	build \
	clean \
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
