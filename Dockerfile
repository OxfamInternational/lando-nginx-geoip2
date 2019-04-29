FROM bitnami/minideb-extras-base:stretch-r229
LABEL maintainer "Bitnami <containers@bitnami.com>"

ENV BITNAMI_PKG_CHMOD="-R g+rwX" \
    BITNAMI_PKG_EXTRA_DIRS="/bitnami/nginx/conf" \
    HOME="/" \
    OS_ARCH="amd64" \
    OS_FLAVOUR="debian-9" \
    OS_NAME="linux"

# Install required system packages and dependencies
RUN install_packages wget curl git build-essential autoconf libtool libpcre3 libpcre3-dev libssl-dev libc6 libssl1.1 zlib1g zlibc zlib1g-dev gettext automake

# Download MaxMind GeoLite2 databases
RUN mkdir -p /opt/bitnami/nginx/conf/geoip &&\
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz &&\
    gunzip GeoLite2-City.mmdb.gz &&\
    mv GeoLite2-City.mmdb /opt/bitnami/nginx/conf/geoip/ &&\
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz &&\
    gunzip GeoLite2-Country.mmdb.gz &&\
    mv GeoLite2-Country.mmdb /opt/bitnami/nginx/conf/geoip/

# Install C library for reading MaxMind DB files
# Resource: https://github.com/maxmind/libmaxminddb
RUN git clone --recursive https://github.com/maxmind/libmaxminddb.git &&\
    cd libmaxminddb &&\
    autoreconf -f -i &&\
    ./bootstrap &&\
    ./configure &&\
    make &&\
    make check &&\
    make install &&\
    echo /usr/local/lib  >> /etc/ld.so.conf.d/local.conf &&\
    ldconfig

ENV nginx_version 1.14.2
RUN curl http://nginx.org/download/nginx-$nginx_version.tar.gz | tar xz &&\
    git clone https://github.com/leev/ngx_http_geoip2_module.git

WORKDIR /nginx-$nginx_version

# Compile Nginx
RUN ./configure \
    --prefix=/opt/bitnami/nginx \
    --sbin-path=/opt/bitnami/nginx/sbin/nginx \
    --conf-path=/opt/bitnami/nginx/conf/nginx.conf \
    --error-log-path=/opt/bitnami/nginx/logs/error.log \
    --http-log-path=/opt/bitnami/nginx/logs/access.log \
    --pid-path=/opt/bitnami/nginx/tmp/nginx.pid \
    --lock-path=/opt/bitnami/nginx/tmp/nginx.lock \
    --http-client-body-temp-path=/opt/bitnami/nginx/tmp/client \
    --http-proxy-temp-path=/opt/bitnami/nginx/tmp/proxy \
    --http-fastcgi-temp-path=/opt/bitnami/nginx/tmp/fastcgi \
    --http-uwsgi-temp-path=/opt/bitnami/nginx/tmp/wsgi \
    --http-scgi-temp-path=/opt/bitnami/nginx/tmp/scgi \
    --user=www-data \
    --group=www-data \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-debug \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
    --with-ipv6 \
    --add-module=/ngx_http_geoip2_module &&\
    make &&\
    make install

RUN ln -sf /opt/bitnami/nginx/html /app
RUN ln -sf /dev/stdout /opt/bitnami/nginx/logs/access.log
RUN ln -sf /dev/stderr /opt/bitnami/nginx/logs/error.log

COPY rootfs /
RUN /prepare.sh
ENV BITNAMI_APP_NAME="nginx" \
    BITNAMI_IMAGE_VERSION="1.14.2-debian-9-r125" \
    NAMI_PREFIX="/.nami" \
    NGINX_DAEMON_GROUP="" \
    NGINX_DAEMON_USER="" \
    NGINX_HTTPS_PORT_NUMBER="443" \
    NGINX_HTTP_PORT_NUMBER="8080" \
    PATH="/opt/bitnami/nginx/sbin:$PATH" \
    NGINX_BASEDIR="/opt/bitnami/nginx" \
    NGINX_VOLUME="/bitnami/nginx" \
    NGINX_EXTRAS_DIR="/opt/bitnami/extra/nginx" \
    NGINX_TEMPLATES_DIR="/opt/bitnami/extra/nginx/templates" \
    NGINX_TMPDIR="/opt/bitnami/nginx/tmp" \
    NGINX_CONFDIR="/opt/bitnami/nginx/conf" \
    NGINX_LOGDIR="/opt/bitnami/nginx/logs"
EXPOSE 8080

WORKDIR /app
USER 1001
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/run.sh" ]
