BASE=mebooks/apache-php5
APP=mebooks/php-app
VERSION=`git describe --tags`
CORE_VERSION=HEAD

all: build-base prepare

base: build-base

app: prepare-app build-app

build-base:
	docker build -t $(BASE):$(VERSION) docker/base

prepare-app:
	git archive --format tgz HEAD php-app > docker/app/php-app.tgz

build-app:
	docker build -t $(APP):$(VERSION) docker/app
