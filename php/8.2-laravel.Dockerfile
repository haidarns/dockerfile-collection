# syntax = docker/dockerfile:1.4.0
# Build command :
#   DOCKER_BUILDKIT=1 docker build --rm -f php/8.2-laravel.Dockerfile -t haidarns/php:8.2-laravel-nginx --no-cache .

FROM haidarns/php:8.2-laravel-nginx as GRPC_SOURCE
FROM php:8.2-fpm

# Change www-data user & group id same as host's ubuntu id
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Set working directory
WORKDIR /var/www/

# Setup Node 18 repo
RUN curl -sL https://deb.nodesource.com/setup_18.x -o - | bash

# Install dependencies
RUN apt update -qq && apt install --no-install-recommends -y -qq \
    build-essential \
    cron \
    git \
    jpegoptim optipng pngquant gifsicle libfreetype6-dev libjpeg62-turbo-dev libonig-dev libpng-dev \
    libssl-dev \
    libzip-dev \
    libpq-dev \
    libicu-dev \
    libldap2-dev \
    locales \
    nano \
    nginx \
    nodejs \
    supervisor \
    unzip \
    vim \
    zip \
    python3-pip libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz-subset0 libjpeg-dev libopenjp2-7-dev libffi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install weasyprint pip
RUN pip install weasyprint --break-system-packages

# Install yarn
RUN npm install -s --global yarn

# Install extensions
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
# Start from php8.0 json ext always available
RUN set -x && docker-php-ext-install intl pdo_pgsql pdo_mysql mysqli mbstring zip exif pcntl bcmath gd sockets ldap
RUN MAKEFLAGS="-j 3" pecl install -o -f redis mongodb apcu \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis mongodb apcu

#RUN MAKEFLAGS="-j 3" pecl install -o -f grpc protobuf \
#    && strip --strip-debug /usr/local/lib/php/extensions/*/grpc.so \
#    && rm -rf /tmp/pear \
#    && docker-php-ext-enable grpc protobuf

COPY --from=GRPC_SOURCE /usr/local/lib/php/extensions/no-debug-non-zts-20220829/grpc.so /usr/local/lib/php/extensions/no-debug-non-zts-20220829/
COPY --from=GRPC_SOURCE /usr/local/lib/php/extensions/no-debug-non-zts-20220829/protobuf.so /usr/local/lib/php/extensions/no-debug-non-zts-20220829/
RUN docker-php-ext-enable grpc protobuf

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
