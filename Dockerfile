FROM bitnami/minideb:buster

ENV PHP_VERSION=8.0
ARG APP_DEBUG=true
ENV APP_DEBUG=${APP_DEBUG}

# install some simple linux tools for use in CLI tinkering
RUN apt-get update
RUN install_packages wget curl make apt-transport-https lsb-release ca-certificates supervisor
RUN curl -sL https://deb.nodesource.com/setup_15.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh && install_packages nodejs && rm nodesource_setup.sh
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
RUN apt-get update && install_packages libmpdec-dev zip unzip php-pclzip nano git php${PHP_VERSION} php-dev apache2 libapache2-mod-fcgid php${PHP_VERSION}-fpm php${PHP_VERSION}-common php${PHP_VERSION}-cli php-xml php-curl php-mysql php-bcmath php-mbstring php-intl php-mongodb

RUN mkdir -p /usr/src/php/ext/php-decimal && cd /usr/src/php/ext/php-decimal && git clone https://github.com/php-decimal/ext-decimal.git && cd ext-decimal && git checkout 1.x-php8 && phpize && ./configure && make && make install && rm -r /usr/src/php

# grab the latest version of composer form dockerhub and put the binary in this image
COPY --from=composer:2.0 /usr/bin/composer /usr/local/bin/composer

# enable fastcgi for Apache and set it to work with php
RUN a2enmod proxy_fcgi setenvif rewrite && a2enconf php${PHP_VERSION}-fpm

# this must be done during build time as it can't be done after the image is built
RUN mkdir -p /var/run/php

# copy a customized version of supervisor from host to replace the original one in container
COPY ./.docker/supervisord.conf /etc/supervisord.conf

COPY ./host.conf /etc/apache2/sites-available/000-default.conf
# uncomment if, you need to customize php-fpm config
#COPY ./php-fpm.conf /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

# change log paths from /var to /run
RUN sed -i "s/^error_log = \/var/error_log = \/run/g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
RUN sed -i "s/^;clear_env/clear_env/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
RUN sed -i "s/^variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" /etc/php/${PHP_VERSION}/fpm/php.ini
RUN sed -i "s/^export APACHE_PID_FILE=\/var\/run/export APACHE_PID_FILE=\/run/g" /etc/apache2/envvars
RUN sed -i "s/^export APACHE_LOCK_DIR=\/var\/lock/export APACHE_LOCK_DIR=\/run\/lock/g" /etc/apache2/envvars
RUN sed -i "s/^export APACHE_LOG_DIR=\/var\/log/export APACHE_LOG_DIR=\/run\/log/g" /etc/apache2/envvars
RUN sed -i "s/^\/var\/log/\/run\/log/g" /etc/logrotate.d/apache2
RUN sed -i "s/^\/var\/log/\/run\/log/g" /etc/logrotate.d/php${PHP_VERSION}-fpm

RUN echo "extension=decimal.so" >> /etc/php/${PHP_VERSION}/fpm/php.ini
RUN echo "extension=decimal.so" >> /etc/php/${PHP_VERSION}/cli/php.ini
# optional
RUN echo "ServerName laravel-php-fpm-apache.localhost" >> /etc/apache2/apache2.conf

# remove the built-in index file used to demonstrate a working Apache server
#RUN rm /var/www/html/index.html

# copy actual program source code to the document root of Apache
COPY ./src /var/www

WORKDIR /var/www

RUN if [ -f /var/www/package.json ]; then npm i; if [ $APP_DEBUG = false ]; then npm run production; else npm run development; fi; fi

RUN if [ -f /var/www/composer.json ]; then \
  composer install \
#    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --ansi \
    --no-scripts; fi

RUN chown -R www-data:www-data /var/www
# the following can be used in a wsl2 development environment
#sudo chown -R $USER:www-data storage
#sudo chown -R $USER:www-data bootstrap/cache

RUN echo "FcgidIPCDir /run/mod_fcgid" >> /etc/apache2/apache2.conf
RUN echo "FcgidProcessTableFile /run/mod_fcgid/fcgid_shm" >> /etc/apache2/apache2.conf

CMD ["/usr/bin/supervisord", "-n"]

EXPOSE 80