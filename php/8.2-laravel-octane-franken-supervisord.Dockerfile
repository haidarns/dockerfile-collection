# syntax = docker/dockerfile:1.4.0
# Build command :
#   DOCKER_BUILDKIT=1 docker build --rm -f 8.2-laravel-octane-franken-supervisord.Dockerfile -t haidarns/php:8.2-laravel-octane-franken-supervisord --no-cache .

FROM haidarns/php:8.2-laravel-octane-franken

WORKDIR /var/www/html

# Install dependencies
RUN apt update -qq \
    && apt install --no-install-recommends -y -qq supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
EOF

## Example octane-franken program

# [program:frankenphp]
# user=www-data
# command=php artisan octane:frankenphp --port=8000
# directory=/var/www/html
# process_name=%(program_name)s_%(process_num)02d
# numprocs=1
# autostart=true
# autorestart=false
# startsecs=0
# redirect_stderr=true
# stdout_logfile=/dev/stdout
# stdout_logfile_maxbytes=0

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
