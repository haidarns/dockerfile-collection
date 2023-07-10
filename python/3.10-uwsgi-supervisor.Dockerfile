# Build command :
#   docker build --rm -f 3.10-uwsgi-supervisor.Dockerfile -t haidarns/python:3.10-uwsgi-supervisor --no-cache .

FROM python:3.10-alpine as builder

RUN apk add python3-dev build-base linux-headers pcre-dev \
    && pip install --user uwsgi


# Final Image
FROM python:3.10-alpine

RUN apk add --clean pcre git nano openssh-client mailcap supervisor \
    && mkdir -p /etc/uwsgi/vassals \
    && mkdir -p /etc/supervisor/conf.d/

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

[program:uwsgi]
user=root
command=/root/.local/bin/uwsgi --master --die-on-term --emperor-graceful-shutdown --emperor=/etc/uwsgi/vassals --log-drain='you are running uWSGI as root'
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=true
autorestart=false
startsecs=0
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
EOF

COPY --from=builder /root/.local /root/.local

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
