# syntax = docker/dockerfile:1.4.0
# Build command :
#   DOCKER_BUILDKIT=1 docker build --rm -f 8.2-laravel-octane-franken.Dockerfile -t haidarns/php:8.2-laravel-octane-franken --no-cache .

FROM dunglas/frankenphp:php8.2-bookworm

WORKDIR /var/www/html

RUN curl -sL https://deb.nodesource.com/setup_20.x -o - | bash \
    && apt-get update \
    && apt install --no-install-recommends -y -qq \
        nodejs \
        vim \
        nano \
        zip \
        unzip \
        jpegoptim optipng pngquant gifsicle libfreetype6-dev libjpeg62-turbo-dev libonig-dev libpng-dev \
        libicu-dev libssl-dev libzip-dev libpq-dev \
        weasyprint \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl zip gd pdo_pgsql pcntl


## Example build

# FROM haidarns/php:8.2-laravel-octane-franken

# COPY . .

# RUN composer install \
#     && npm install \
#     && npm run build \
#     && php artisan storage:link \
#     && php artisan octane:install --server=frankenphp \           <-- Must run this
#     && chown -R 1000:1000 .

CMD ["php","artisan","octane:frankenphp","--port=80"]
