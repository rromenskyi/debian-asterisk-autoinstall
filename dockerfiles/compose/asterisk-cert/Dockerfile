# Asterisk for Kubernetes
#
# It is expected that the configuration should be generated separately, as from https://github.com/CyCoreSystems/asterisk-config.
#

FROM debian:bookworm as builder
MAINTAINER Roman Romenskyi "roman220220@gmail.com"

ENV ASTERISK_VER 18.9-cert8-rc1

# Install Asterisk
RUN apt-get update && \
   apt-get install -y libedit-dev git curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev uuid-dev autoconf libpcap-dev libxml2-utils unixodbc-dev odbc-mariadb libspeex-dev libcurl4-openssl-dev libspeexdsp-dev libgsm1-dev sqlite3 libspandsp-dev pkg-config python3-dev openssl libopus-dev liburiparser-dev libmariadb-dev xmlstarlet && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /tmp
RUN curl -o /tmp/asterisk.tar.gz https://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-${ASTERISK_VER}.tar.gz && \
   tar xf /tmp/asterisk.tar.gz && \
   cd /tmp/asterisk-certified-${ASTERISK_VER}

RUN cd /tmp/asterisk-certified-${ASTERISK_VER} &&\
   ./configure --with-pjproject-bundled --with-jansson-bundled --with-spandsp --with-opus && \
   make menuselect.makeopts && \
   menuselect/menuselect --disable CORE-SOUNDS-EN-GSM --enable CORE-SOUNDS-EN-ULAW --enable codec_opus --disable BUILD_NATIVE --disable chan_sip menuselect.makeopts && \
   make && \
   make install && \
   rm -Rf /tmp/*

FROM debian:bookworm
COPY --from=builder /usr/sbin/asterisk /usr/sbin/
COPY --from=builder /usr/sbin/safe_asterisk /usr/sbin/
COPY --from=builder /usr/lib/libasterisk* /usr/lib/
COPY --from=builder /usr/lib/asterisk/ /usr/lib/asterisk
COPY --from=builder /var/lib/asterisk/ /var/lib/asterisk
COPY --from=builder /var/spool/asterisk/ /var/spool/asterisk

# Add required runtime libs
RUN apt-get update && \
   apt-get install -y gnupg libjansson4 xml2 libncurses5 libspeex1 libcurl4-openssl-dev libedit2 libspeexdsp1 libgsm1 uuid libsqlite3-0 libspandsp2 libssl3 libopus0 liburiparser1 xmlstarlet odbc-mariadb libodbc2 flac curl wget && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add sngrep
COPY irontec.list /etc/apt/sources.list.d/irontec.list
RUN curl -L http://packages.irontec.com/public.key | apt-key add -
RUN apt-get update && \
   apt-get install -y sngrep && \
   rm -Rf /var/lib/apt/lists/ /tmp/* /var/tmp/*

# Add entrypoint script
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5060/udp 5060/tcp
VOLUME /var/lib/asterisk/sounds /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk /etc/asterisk

COPY odbc.ini /etc/odbc.ini

WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
CMD []
