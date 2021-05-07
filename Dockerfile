FROM debian:buster-slim

ENV PHP_VERSION=8.0

# install some simple linux tools for use in CLI tinkering
RUN apt-get update
RUN apt-get -y install wget curl apt-transport-https lsb-release ca-certificates supervisor
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
RUN apt-get update
RUN apt-get -y install nano php${PHP_VERSION} apache2 libapache2-mod-fcgid php${PHP_VERSION}-fpm php${PHP_VERSION}-common php${PHP_VERSION}-cli php-curl php-mysql php-bcmath php-mbstring php-intl php-mongodb

# grab the latest version of composer form dockerhub and put the binary in this image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# enable fastcgi for Apache and set it to work with php
RUN a2enmod proxy_fcgi setenvif rewrite
RUN a2enconf php${PHP_VERSION}-fpm

# this must be done during build time as it can't be done after the image is built
RUN mkdir -p /var/run/php

# copy a customized version of supervisor from host to replace the original one in container
COPY ./.docker/supervisord.conf /etc/supervisord.conf

COPY ./host.conf /etc/apache2/sites-available/000-default.conf
# uncomment if, you need to customize php-fpm config
#COPY ./php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

# change log paths from /var to /run
RUN sed -i "s/^error_log = \/var/error_log = \/run/g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
RUN sed -i "s/^export APACHE_PID_FILE=\/var\/run/export APACHE_PID_FILE=\/run/g" /etc/apache2/envvars
RUN sed -i "s/^export APACHE_LOCK_DIR=\/var\/lock/export APACHE_LOCK_DIR=\/run\/lock/g" /etc/apache2/envvars
RUN sed -i "s/^export APACHE_LOG_DIR=\/var\/log/export APACHE_LOG_DIR=\/run\/log/g" /etc/apache2/envvars
RUN sed -i "s/^\/var\/log/\/run\/log/g" /etc/logrotate.d/apache2
RUN sed -i "s/^\/var\/log/\/run\/log/g" /etc/logrotate.d/php${PHP_VERSION}-fpm

# remove the built-in index file used to demonstrate a working Apache server
#RUN rm /var/www/html/index.html

# copy actual program source code to the document root of Apache
COPY ./src /var/www
#RUN mv -f /var/www/public/* /var/www/html && rm

RUN chown -R www-data:www-data /var/www

# optional
RUN echo "ServerName dockertest.local" >> /etc/apache2/apache2.conf

RUN echo "FcgidIPCDir /run/mod_fcgid" >> /etc/apache2/apache2.conf
RUN echo "FcgidProcessTableFile /run/mod_fcgid/fcgid_shm" >> /etc/apache2/apache2.conf

CMD ["/usr/bin/supervisord", "-n"]

EXPOSE 80