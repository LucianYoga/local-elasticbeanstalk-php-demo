NAME=mebooks/apache-php5
VERSION=`git describe --tags`
CORE_VERSION=HEAD

all: prepare build

prepare:
    git archive --format tgz HEAD php-app > docker/php-app.tgz

build:
    docker build -t $(NAME):$(VERSION) docker
