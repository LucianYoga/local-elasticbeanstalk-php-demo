# refer: https://github.com/hopsoft/relay/wiki/How-to-Deploy-Docker-apps-to-Elastic-Beanstalk
FROM ubuntu:14.04
MAINTAINER Jason Darwin <jcdarwin@gmail.com>

# set environment variables
ENV APP_NAME=eb-demo-php

# install apache and php5
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y install apache2 php5 libapache2-mod-php5 php5-mcrypt php5-json curl git supervisor && \
    apt-get clean && \
    rm -rf /var/www/html && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# enable apache defaults and mods
RUN update-rc.d apache2 defaults && \
    a2enmod rewrite

# update php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 20M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 20M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/short_open_tag\s*=\s*Off/short_open_tag = On/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini

# fix for php5-mcrypt
RUN /usr/sbin/php5enmod mcrypt

# install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# ensure log directories exist
RUN mkdir /var/log/supervisord/ && \
    mkdir /var/log/apache2/ && \
    mkdir /var/log/init/

# setup logrotate
ADD logrotate /etc/logrotate.d/${APP_NAME}

# Add supervisor
ADD supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# add init script
ADD init.sh /init.sh

# make our init script runnable
RUN chmod a+x /init.sh

# Supervisor starts our processes, including the init script
CMD ["/bin/bash", "/usr/local/bin/supervisord -n"]

#ENTRYPOINT ["/init.sh"]

EXPOSE 80 443
