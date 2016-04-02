BASE_IMAGE=mebooks/apache-php5
APP_IMAGE=mebooks/php-app
APP=php-app
VERSION=`git describe --tags`
CORE_VERSION=HEAD

all: build-base prepare

base: build-base

app: prepare-app build-app

build-base:
	docker build -t $(BASE_IMAGE):$(VERSION) docker/base

prepare-app:
	# Update Dockerrun.aws.json with the current image version
	sed -i '' "s~${APP_IMAGE}\:[^\"]*~${APP_IMAGE}\:$(VERSION)~g" Dockerrun.aws.json
	git archive --format tgz HEAD $(APP) > docker/app/$(APP).tgz

build-app:
	docker build -t $(APP_IMAGE):$(VERSION) docker/app
