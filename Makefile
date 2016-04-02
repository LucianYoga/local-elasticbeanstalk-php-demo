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
	ifeq $(ECR_REGISTRY)
		#Login to ECR Repository
		LOGIN_STRING=`aws ecr get-login --profile $(ECR_PROFILE)`
		${LOGIN_STRING}

		# Tag and push our image -- we're presuming we've already set up a repository
		# on our registry with the same name as our image.
		docker tag $(BASE_IMAGE):latest $(ECR_REGISTRY)/$(BASE_IMAGE):latest
		docker push $(ECR_REGISTRY)/$(BASE_IMAGE):latest
	else
		docker login --username=$(DOCKER_USER) --email=$(DOCKER_EMAIL) --password=$(DOCKER_PASSWORD)
		docker push $(BASE_IMAGE)
	endif

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
	ifeq $(ECR_REGISTRY)
		#Login to ECR Repository
		LOGIN_STRING=`aws ecr get-login --profile $(ECR_PROFILE)`
		${LOGIN_STRING}

		# Tag and push our image -- we're presuming we've already set up a repository
		# on our registry with the same name as our image.
		docker tag $(APP_IMAGE):$(VERSION) $(ECR_REGISTRY)/$(APP_IMAGE):$(VERSION)
		docker push $(ECR_REGISTRY)/$(APP_IMAGE):$(VERSION)
	else
		docker login --username=$(DOCKER_USER) --email=$(DOCKER_EMAIL) --password=$(DOCKER_PASSWORD)
		docker push $(APP_IMAGE)
	endif

#
# Our Elastic Beanstalk tasks
#
create-environment:
	eb create -v \
		--cfg $(EB_APP) \
		--scale $(EB_SCALE_MIN) \
		--cname $(EB_ENVIRONMENT) \
		$(EB_ENVIRONMENT)
