# syntax = docker/dockerfile:1.4.0
# Build command :
#   DOCKER_BUILDKIT=1 docker build --rm -f 8.2-laravel.Dockerfile -t haidarns/php:8.2-laravel-nginx --no-cache .

FROM php:8.2-fpm

# Change www-data user & group id same as host's ubuntu id
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Set working directory
WORKDIR /var/www/

# Setup Node 16 repo
RUN curl -sL https://deb.nodesource.com/setup_16.x -o - | bash

# Install dependencies
RUN apt-get update && apt-get install -y -qq \
    build-essential \
    cron \
    git \
    jpegoptim optipng pngquant gifsicle libfreetype6-dev libjpeg62-turbo-dev libonig-dev libpng-dev \
    libssl-dev \
    libzip-dev \
    locales \
    nano \
    nginx \
    nodejs \
    supervisor \
    unzip \
    vim \
    weasyprint \
    zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install yarn
RUN npm install --global yarn

# Install extensions
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/
# Start from php8.0 json ext always available
RUN docker-php-ext-install pdo_mysql mysqli mbstring zip exif pcntl bcmath gd
RUN pecl install -o -f redis mongodb apcu \
    &&  rm -rf /tmp/pear \
    && docker-php-ext-enable redis mongodb apcu

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN chown -R www-data:www-data /var/www

RUN <<EOF cat > /etc/supervisor/supervisord.conf
[supervisord]
nodaemon=true

[supervisorctl]
[inet_http_server]
port=127.0.0.1:9001

[rpcinterface:supervisor]
supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface

[include]
files = /etc/supervisor/conf.d/*.conf

[program:nginx]
user=root
command=nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=true
autorestart=false
startsecs=0
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0

[program:php-fpm]
user=root
command=/usr/local/sbin/php-fpm -R -F -c /usr/local/etc/php-fpm.conf
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=true
autorestart=false
startsecs=0
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
EOF

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]