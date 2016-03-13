# Local Elastic Beanstalk PHP Demo

This is a demonstration of running multiple containers locally using Amazon's Elastic Beanstalk.

In truth, all Elastic Beanstalk will be doing for us here will be generating a `docker-compose.yml`
file (in `.elasticbeanstalk`), but once we're happy with the results, we can easily use the same
configuration to run our containers on AWS usng Elastic Beanstalk.

We want to be able to:

* Install and use Docker on Mac OSX
* Build a custom apache-php5 Docker image using a `Dockerfile`, fully provisioned and ready for our app
* Build a Docker image containing our app on top of this apache-php5 Docker image
* Run up containers locally from the Docker image using Elastic Beanstalk's `eb local run`

Our app will do nothing more arduous than displaying the information generated by `phpinfo()`
and show that it can connect to a MySQL database.

Note that we build a apache-php5 Docker image first, and then another image containing our app
on top of this image. This allows us to re-use the existing apache-php5 Docker image
whenever our app changes, and thus speeds up our builds.


## Installation

We use `docker-machine` on OSX via the [Docker ToolBox](https://www.docker.com/products/docker-toolbox).
As we're using Max OSX, this means that we'll end up with a Virtualbox Linux VM that will be used to run Docker.

Start our `docker-machine`:

	docker-machine start default

Set our environment variables:

	# Retrieve our config
	docker-machine config default

	# Set our environment values base on the docker-machine config
	export DOCKER_CERT_PATH=/Users/whoever/.docker/machine/certs
	export DOCKER_TLS_VERIFY=1
	export DOCKER_HOST=tcp://192.168.99.100:2376


## Setup docker so we can use it from our current shell

Port-forward in `VirtualBox`, so we can access port 80 transparently:

	VBoxManage list vms
	VBoxManage modifyvm "defaut" --natpf1 "guestnginx,tcp,,80,,80"

Load the environment so we can use docker from the local shell:

	eval "$(docker-machine env default)"

Once installed, we can see that `docker` is at version 10.1:

	docker -v
	$ Docker version 1.10.2, build c3959b1


## Install `awsebcli`

We install the `awsebcli` using homebrew:

	brew install awsebcli

However, [there's a problem with the version compatibility check](https://forums.aws.amazon.com/thread.jspa?threadID=225425), meaning that awsebcli thinks that docker 1.10.2 is < docker 1.6, and we receive the following message:

	"You must install Docker version 1.6.0 to continue. If you are using Mac OS X, ensure you have boot2docker version 1.6.0. Currently, "eb local" does not support Windows."

To rectify this, currently we must edit `/usr/local/Cellar/aws-elasticbeanstalk/3.7.3/libexec/lib/python2.7/site-packages/ebcli/containers/compat.py` as follows, by changing:

	def supported_docker_installed():
		"""
		Return whether proper Docker version is installed.
		:return: bool
		"""

		try:
			return commands.version() >= SUPPORTED_DOCKER_V
		# OSError = Not installed
		# CommandError = docker versions less than 1.5 give exit code 1
		# with 'docker --version'.
		except (OSError, CommandError):
			return False

to

	def supported_docker_installed():
		"""
		Return whether proper Docker version is installed.
		:return: bool
		"""

		try:
			#return commands.version() >= SUPPORTED_DOCKER_V
			return True
		# OSError = Not installed
		# CommandError = docker versions less than 1.5 give exit code 1
		# with 'docker --version'.
		except (OSError, CommandError):
			return False


## Installing Composer

	curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

Use composer to install our dependencies

	cd php-app
	composer install


## Environment variables

We need to make certain environment variables available to our PHP scripts, particularly
those to do with connecting to our MySQL container.

To do this, we create a `php-app/.env` file, with placeholders for the expected
environment variables:

	# php-app/.env
	# The variables below are replaced during container startup by init.sh
	DB_HOST="${MYSQL_PORT_3306_TCP_ADDR}"
	DB_DATABASE="${MYSQL_ENV_MYSQL_DATABASE}"
	DB_USERNAME=root
	DB_PASSWORD="${MYSQL_ENV_MYSQL_ROOT_PASSWORD}"

We then use our `init.sh` script to read the environment variables during the
initialisation of our PHP container, and replace the placeholders in `.env` with
the values:

	# Make a copy of our .env file, as we don't want to pollute the original
	cp /var/www/html/.env /tmp/

	# Update the app configuration to make the service environment
	# variables available.
	function setEnvironmentVariable() {
		if [ -z "$2" ]; then
			echo "Environment variable '$1' not set."
			return
		fi

		# Check whether variable already exists
		if grep -q "\${$1}" /tmp/.env; then
			# Reset variable
			sed -i "s/\${$1}/$2/g" /tmp/.env
		fi
	}

	# Grep for variables that look like MySQL (MYSQL)
	for _curVar in `env | grep MYSQL | awk -F = '{print $1}'`;do
		# awk has split them by the equals sign
		# Pass the name and value to our function
		setEnvironmentVariable ${_curVar} ${!_curVar}
	done

	# Now that /tmp/.env is populated, we can start/restart apache
	# and let our PHP scripts access them.
	service apache2 restart


## Create our Makefile

We use a Makefile to make our builds slightly easier:

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
		git archive --format tgz HEAD $(APP) > docker/app/$(APP).tgz

	build-app:
		docker build -t $(APP_IMAGE):$(VERSION) docker/app


## Build the docker images

Commit and tag our changes

	git tag 2.3.0

Build our apache-php base docker image:

	make base

	docker images

Edit `docker/app/Dockerfile` and ensure that we refering to the same version
as that that we just built:

	FROM mebooks/apache-php5:2.3.0

Build our app docker image:

	make app


## Check that our containers function as expected

	# Start just the PHP container
	docker run -tid -p 80:80 mebooks/php-app:2.3.0

	# Start both containers linked
	docker run -p 3306:3306 \
		-e MYSQL_ROOT_PASSWORD=password \
		-e MYSQL_DATABASE=my_db \
		-d \
		--name mysqlserver \
		mysql

	docker run -tid -p 80:80 \
		--link mysqlserver:mysqldb \
		mebooks/php-app:2.3.0

We should now be able to see the PHP Info details at the address reported by `docker-machine ip`, e.g.:

	docker-machine ip
	$ http://192.168.99.100/

We should also be able to see a simple example of connecting to our MySQL database at http://192.168.99.100/mysql.php


## Push our images to docker.io

Login to our docker account:

	# Enter the username, password and email when prompted
	docker login

	# Alternatively, specify username and email, and enter password when prompted
	docker login --username=mebooks --email=jcdarwin@gmail.com

The login will create a config file at `~/.docker/config.json` if it doesn't already exist

AWS currently uses an older format of the docker config, so we need to change our current
`~/.docker/config.json` to the required format by removing the `auths` wrapper:

	# ~/.docker/config.json
	{
		"auths": {
			"https://index.docker.io/v1/": {
				"auth": "WHATEVER",
				"email": "jcdarwin@gmail.com"
			}
		}
	}

becomes

	# ~/.docker/.dockercfg.json
	{
			"https://index.docker.io/v1/": {
				"auth": "WHATEVER",
				"email": "jcdarwin@gmail.com"
			}
	}

We now need to push this to a suitable s3 bucket so Elastic Beanstalk can use it to download
our images from our private repository.

	s3cmd put ~/.docker/.dockercfg.json s3://elasticbeanstalk-us-west-1-342732433199

Push our images to docker:

	docker push mebooks/apache-php5
	docker push mebooks/php-app


## Create our `Dockerrun.aws.json` (multi-container version)

We can use a multi-container `Dockerrun.aws.json` if we want to use `eb local run`
to spin up both our `php-app` container and an associated `mysql` container.

	{
		"AWSEBDockerrunVersion": 2,
		"containerDefinitions": [
			{
				"name": "mysql",
				"image": "mysql:5.6",
				"essential": true,
				"portMappings": [
					{
						"hostPort": 3306,
						"containerPort": 3306
					}
				],
				"environment": [
					{
						"name": "MYSQL_ROOT_PASSWORD",
						"value": "password"
					},
					{
						"name": "MYSQL_DATABASE",
						"value": "my_db"
					}
				]
			},
			{
				"name": "php-app",
				"image": "mebooks/php-app",
				"essential": true,
				"memory": 128,
				"portMappings": [
					{
						"hostPort": 80,
						"containerPort": 80
					}
				],
				"links": [
					"mysql"
				]
			}
		]
	}


Note that we specify a (very) weak `MYSQL_ROOT_PASSWORD` in our `Dockerrun.aws.json`
-- you'll want to change this and not have it under version control.


## Run our containers locally

Finally, use `eb local` to create our docker containers locally:

	eb local run

In a second terminal

	eb local status
	docker ps


## Accessing the containers

Find the appropriate container id, and start a bash shell on it:

	docker ps

	$ CONTAINER ID        IMAGE
	$ 832af3ff45d8        mebooks/apache-php5:latest
	$ fc6a9553583f        mysql:5.6

	# Access our PHP container
	docker exec -it 832af3ff45d8 bash

Alternatively, we can use `eb` to find the details, include human-readable container names

	eb local status

	$ Platform: 64bit Amazon Linux 2015.09 v2.0.8 running Multi-container Docker 1.9.1 (Generic)
	$ Container name: elasticbeanstalk_mysql_1
	$ Container ip: 127.0.0.1
	$ Container running: True
	$ Exposed host port(s): 3306
	$ Full local URL(s): 127.0.0.1:3306

	$ Container name: elasticbeanstalk_phpapache_1
	$ Container ip: 127.0.0.1
	$ Container running: True
	$ Exposed host port(s): 80
	$ Full local URL(s): 127.0.0.1:80

Access our PHP container

	docker exec -it elasticbeanstalk_phpapache_1 bash

	# check our apache config
	apachectl configtest

	# view our apache config
	cat /etc/apache2/sites-enabled/vhost.conf

	# Find the ip of our MySQL container
	env | grep MYSQL_1_PORT_3306_TCP_ADDR

	$ ELASTICBEANSTALK_MYSQL_1_PORT_3306_TCP_ADDR=172.17.0.2
	$ MYSQL_1_PORT_3306_TCP_ADDR=172.17.0.2

	# Login to mysql
	mysql -u root -h 172.17.0.2  -p

Access our MySQL container

	docker exec -it elasticbeanstalk_mysql_1 bash

	# Display our databases -- we should see my_db
	mysql -u root -p -e "show databases;"


## Create our `Dockerrun.aws.json` (single container version)

Although the multi-container version above is useful for testing locally,
in production we'll be using RDS to host MySQL, so we'll use a single container
`Dockerrun.aws.json`


## Initialise our Elastic Beanstalk app

Now, we need to initialise our `.elasticbeanstalk/config.yml`:

	eb init


## Create our Elastic Beanstalk application environment

Refer https://github.com/hopsoft/relay/wiki/How-to-Deploy-Docker-apps-to-Elastic-Beanstalk


## Cleaning up

Once we're finished, remove our containers

	docker rm 832af3ff45d8 fc6a9553583f

If we're finished with our image, we can delete it:

	docker rmi mebooks/apache-php5


## Further

* http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create_deploy_docker-eblocal.html
* http://victorlin.me/posts/2014/11/26/running-docker-with-aws-elastic-beanstalk
* https://github.com/hopsoft/relay/wiki/How-to-Deploy-Docker-apps-to-Elastic-Beanstalk
* http://www.sitepoint.com/docker-and-dockerfiles-made-easy/
* http://www.michaelgallego.fr/blog/2015/07/18/using-elastic-beanstalk-multi-container-with-php/
