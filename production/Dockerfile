# refer: https://github.com/hopsoft/relay/wiki/How-to-Deploy-Docker-apps-to-Elastic-Beanstalk
FROM ubuntu:14.04
MAINTAINER DARWIN Jason <jcdarwin@gmail.com>

# set environment variables
ENV app_name=eb-demo-php

# install Apache and PHP5
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y install apache2 php5 libapache2-mod-php5 php5-mcrypt php5-json curl git && \
    apt-get clean && \
    update-rc.d apache2 defaults && \
    php5enmod mcrypt && \
    a2enmod rewrite && \
    rm -rf /var/www/html && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    apt-get clean && \
    mkdir /etc/my_init.d/ && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini

# setup logrotate
ADD logrotate /etc/logrotate.d/${app_name}

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND

# add boot script
ADD boot.sh /etc/my_init.d/boot.sh

# make our boot script runnable
RUN chmod a+x /etc/my_init.d/boot.sh

#ENTRYPOINT ["/etc/my_init.d/boot.sh"]

EXPOSE 80
EXPOSE 443
