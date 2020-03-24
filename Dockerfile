FROM alpine:latest
LABEL maintainer "Tatsuya Kobayashi <SangatsuUsagi@SangatsuUsagi.com>"

##################
##   BUILDING   ##
##################

# Versions to use
ENV netatalk_version 3.1.11

WORKDIR /

# Prerequisites
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
      bash \
      curl \
      libldap \
      libgcrypt \
      python \
      dbus \
      dbus-glib \
      py-dbus \
      linux-pam \
      cracklib \
      db \
      libevent \
      file \
      acl \
      openssl \
      supervisor && \
    apk add --no-cache --virtual .build-deps \
      build-base \
      autoconf \
      automake \
      libtool \
      libgcrypt-dev \
      linux-pam-dev \
      cracklib-dev \
      acl-dev \
      db-dev \
      dbus-dev \
      libevent-dev && \
    ln -s -f /bin/true /usr/bin/chfn && \
    cd /tmp && \
    curl -o netatalk-${netatalk_version}.tar.gz -L https://downloads.sourceforge.net/project/netatalk/netatalk/${netatalk_version}/netatalk-${netatalk_version}.tar.gz && \
    tar xvf netatalk-${netatalk_version}.tar.gz && \
    cd netatalk-${netatalk_version} && \
    CFLAGS="-Wno-unused-result -O2" ./configure \
      --prefix=/usr \
      --localstatedir=/var/state \
      --sysconfdir=/etc \
      --with-dbus-sysconf-dir=/etc/dbus-1/system.d/ \
      --with-init-style=debian-sysv \
      --sbindir=/usr/bin \
      --enable-quota \
      --with-tdb \
      --enable-silent-rules \
      --with-cracklib \
      --with-cnid-cdb-backend \
      --enable-pgp-uam \
      --with-acls && \
    make && \
    make install && \
    cd /tmp && \
    rm -rf netatalk-${netatalk_version} netatalk-${netatalk_version}.tar.gz && \
    apk del .build-deps

RUN mkdir -p /timemachine && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /conf.d/netatalk

# Create the log file
RUN touch /var/log/afpd.log

COPY entrypoint.sh /entrypoint.sh
COPY start_netatalk.sh /start_netatalk.sh
COPY bin/add-home-account /usr/bin/add-home-account
COPY bin/add-afp-account /usr/bin/add-afp-account
COPY bin/add-tm-account /usr/bin/add-tm-account
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY afp.conf /etc/afp.conf

EXPOSE 548 636

VOLUME ["/timemachine"]

CMD ["/entrypoint.sh"]
