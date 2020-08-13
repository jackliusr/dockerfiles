FROM php:7.0.30-apache-jessie

#RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak
#ADD sources.list /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng12-dev \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) gd

RUN apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git && \
    rm -rf /var/lib/apt/lists/*

RUN pecl channel-update pecl.php.net
RUN pecl install xdebug-2.5.5 && docker-php-ext-enable xdebug
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli
#RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/  &&  \
#    docker-php-ext-install -j$(nproc) gd
RUN echo 'zend_extension="/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so"' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_port=9000' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_connect_back=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.xdebug.idekey=IDEA_DEBUG' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_host=192.111.110.196' >> /usr/local/etc/php/php.ini

COPY uploads /var/www/html
RUN chown -hR www-data:www-data /var/www/html
# make apache2 can bind on Priviliged ports as non root users
RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/apache2
RUN getcap /usr/sbin/apache2
USER www-data
