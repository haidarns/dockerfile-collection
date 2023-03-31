# Build command :
#   docker build --rm -f 3.10-uwsgi.Dockerfile -t haidarns/python:3.10-uwsgi --no-cache .

FROM python:3.10-alpine as builder

RUN apk add python3-dev build-base linux-headers pcre-dev \
    && pip install --user uwsgi


# Final Image
FROM python:3.10-alpine

RUN apk add --clean pcre git nano ssh mailcap \
    && mkdir -p /etc/uwsgi/vassals

COPY --from=builder /root/.local /root/.local

CMD ["/root/.local/bin/uwsgi", "--master", "--die-on-term", "--emperor-graceful-shutdown", "--emperor=/etc/uwsgi/vassals", "--log-drain='you are running uWSGI as root'"]
