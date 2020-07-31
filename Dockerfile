FROM php:7.1.33-fpm-alpine3.9

RUN sed -i s,http://dl-cdn.alpinelinux.org,http://mirrors.aliyun.com,g  /etc/apk/repositories \
    && apk update && apk add \
        autoconf g++ libtool make pcre-dev \
        bash git nginx supervisor \
    && mkdir /etc/supervisor.d/

#####################################
# basic configuration files:
#####################################

COPY ./supervisor.d/* /etc/supervisor.d/
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY ./php/php.ini /usr/local/etc/php/conf.d/php.ini

#####################################
# php mysql extension:
#####################################
RUN docker-php-ext-install pdo pdo_mysql

#####################################
# GIT:
#####################################

ONBUILD ARG INSTALL_GIT=true
ONBUILD RUN if [ ${INSTALL_GIT} = true ]; then \
    echo "Install Composer" \
    && apk add git \
;fi

#####################################
# composer:
#####################################

ONBUILD ARG INSTALL_COMPOSER=true
ONBUILD RUN if [ ${INSTALL_COMPOSER} = true ]; then \
    echo "Install Composer" \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === 'a5c698ffe4b8e849a443b120cd5ba38043260d5c4023dbf93e1558871f1f07f58274fc6f4c93bcfd858c6bd0775cd8d1') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --no-ansi --install-dir=/usr/bin --filename=composer --version=1.9.0 \
    && composer --ansi --version --no-interaction \
    && php -r "unlink('composer-setup.php');" \
;fi

#####################################
# php phpRedis:
#####################################

ONBUILD ARG INSTALL_REDIS=false
ONBUILD RUN if [ ${INSTALL_REDIS} = true ]; then \
    echo "Install Redis" \
    && pecl install redis \
    && echo "extension=redis.so" >> /usr/local/etc/php/conf.d/redis.ini \
;fi

#####################################
# zip:
#####################################

ONBUILD ARG INSTALL_ZIP=false
ONBUILD RUN if [ ${INSTALL_ZIP} = true ]; then \
    echo "Install ZIP" \
    && apk add zlib-dev \
    && docker-php-ext-install zip \
;fi

#####################################
# imagick:
#####################################

ONBUILD ARG INSTALL_IMAGICK=false
ONBUILD RUN if [ ${INSTALL_IMAGICK} = true ]; then \
    echo "Install IMAGICK" \
    && apk add imagemagick-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
;fi

#####################################
# imap:
#####################################

ONBUILD ARG INSTALL_IMAP=false
ONBUILD RUN if [ ${INSTALL_IMAP} = true ]; then \
    echo "Install IMAP" \
    && apk add imap-dev \
    && docker-php-ext-configure imap --with-imap --with-imap-ssl \
    && docker-php-ext-install imap \
;fi

#####################################
# xdebug:
#####################################

ONBUILD ARG INSTALL_XDEBUG=false
ONBUILD RUN if [ ${INSTALL_XDEBUG} = true ]; then \
    apk add --virtual .build-dependencies make m4 autoconf g++ wget \
    && wget -O /tmp/xdebug-2.6.0.tgz http://pecl.php.net/get/xdebug-2.6.0.tgz \
    && pecl install /tmp/xdebug-2.6.0.tgz  \ 
    && docker-php-ext-enable xdebug \
    && rm -f /tmp/xdebug-2.6.0.tgz \
    && apk del --purge .build-dependencies \
;fi

#####################################
# nodejs:
#####################################

ONBUILD ARG INSTALL_NODEJS=false
ONBUILD RUN if [ ${INSTALL_NODEJS} = true ]; then \
    apk add nodejs npm \
;fi

#####################################
# imagemagick:
#####################################

ONBUILD ARG INSTALL_IMAGE_MAGICK=false
ONBUILD RUN if [ ${INSTALL_IMAGE_MAGICK} = true ]; then \
    apk add imagemagick \
;fi

#####################################
# graphicsmagick: 
#####################################

ONBUILD ARG INSTALL_GRAPHICS_MAGICK=false
ONBUILD RUN if [ ${INSTALL_GRAPHICS_MAGICK} = true ]; then \
    apk add graphicsmagick \
;fi

#####################################
# poppler: 
#####################################

ONBUILD ARG INSTALL_POPPLER=false
ONBUILD RUN if [ ${INSTALL_POPPLER} = true ]; then \
    apk add poppler-utils \
;fi

#####################################
# clean:
#####################################
ONBUILD RUN apk del autoconf g++ libtool make pcre-dev

# RUN echo "alias phpunit=\"./vendor/bin/phpunit\"" >> ~/.bashrc

WORKDIR /var/www

CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
