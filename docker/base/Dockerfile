# Build our base apache-php5 image
#
# Refer:
# * https://github.com/hopsoft/relay/wiki/How-to-Deploy-Docker-apps-to-Elastic-Beanstalk
# * https://github.com/phusion/baseimage-docker
FROM phusion/baseimage:0.9.18
MAINTAINER Jason Darwin <jcdarwin@gmail.com>

# install apache and php5
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
    apt-get -y install apache2 php5 libapache2-mod-php5 php5-mysql php5-mcrypt php5-json curl git mysql-client

# enable apache defaults and mods
RUN update-rc.d apache2 defaults && \
    a2enmod rewrite

# update php.ini
RUN sed -i -e "s/memory_limit\s*=\s*\d+M/memory_limit = 256M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 64M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 20M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/short_open_tag\s*=\s*Off/short_open_tag = On/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
# log to stderr
RUN sed -i -e "s/error_log = .*$/error_log = \/var\/log\/php/g" /etc/php5/apache2/php.ini && \
    mkdir /var/log/php

# fix for php5-mcrypt
RUN /usr/sbin/php5enmod mcrypt

# install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# use baseimage-docker's init system.
CMD ["/sbin/my_init"]

VOLUME ["/var/log"]

EXPOSE 80 443
