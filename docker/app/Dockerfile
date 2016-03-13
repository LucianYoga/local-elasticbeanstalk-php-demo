# Build our app image on top of our apache-php5 base image
#
# Refer:
# * https://github.com/hopsoft/relay/wiki/How-to-Deploy-Docker-apps-to-Elastic-Beanstalk
# * https://github.com/phusion/baseimage-docker
FROM mebooks/apache-php5:2.2.0
MAINTAINER Jason Darwin <jcdarwin@gmail.com>

# set environment variables
ENV APP=php-app

# setup logrotate
ADD logrotate /etc/logrotate.d/${APP}

# add our apache conf
ADD config/${APP}.conf /etc/apache2/sites-available
RUN a2ensite ${APP} && \
    a2dissite 000-default

# add our app (it gets automatically ungzipped/untarred)
ADD ${APP}.tgz /var/www

# install our dependencies
RUN cd /var/www/${APP} && \
    /usr/local/bin/composer install

# add init script
ADD init.sh /etc/my_init.d/init.sh

# make our init script runnable
RUN chmod a+x /etc/my_init.d/init.sh

# clean up
RUN rm -rf /var/www/html

# use baseimage-docker's init system.
CMD ["/sbin/my_init"]

VOLUME ["/var/log"]

EXPOSE 80 443
