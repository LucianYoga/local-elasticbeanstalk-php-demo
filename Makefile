include .env_local
BASE_IMAGE=mebooks/apache-php5
APP_IMAGE=mebooks/php-app
APP=php-app
VERSION=`git describe --tags`
CORE_VERSION=HEAD

all: build-base prepare

base: build-base push-base

app: prepare-app build-app push-app

environment: create-environment

#
# Our base image tasks
#
build-base:
	docker build -t $(BASE_IMAGE):$(VERSION) docker/base

push-base:
	docker login --username=$(DOCKER_USER) --email=$(DOCKER_EMAIL) --password=$(DOCKER_PASSWORD)
	docker push $(BASE_IMAGE)

#
# Our app image tasks
#
prepare-app:
	# Update Dockerrun.aws.json with the current image version
	sed -i '' "s~${APP_IMAGE}\:[^\"]*~${APP_IMAGE}\:$(VERSION)~g" Dockerrun.aws.json
	git archive --format tgz HEAD $(APP) > docker/app/$(APP).tgz

build-app:
	docker build -t $(APP_IMAGE):$(VERSION) docker/app

push-app:
	docker login --username=$(DOCKER_USER) --email=$(DOCKER_EMAIL) --password=$(DOCKER_PASSWORD)
	docker push $(APP_IMAGE)

#
# Our Elastic Beanstalk tasks
#
create-environment:
	eb create -v \
		--cfg $(EB_APP) \
		--scale $(EB_SCALE_MIN) \
		--cname $(EB_ENVIRONMENT) \
		$(EB_ENVIRONMENT)
