NAME=mebooks/apache-php5
VERSION=`git describe`
CORE_VERSION=HEAD

all: prepare build

prepare:
    git archive -o docker/php-app.tar HEAD

build:
    docker build -t $(NAME):$(VERSION) --rm docker
