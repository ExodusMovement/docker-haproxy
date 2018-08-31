FROM alpine:3.8 as builder

ENV HAPROXY_VERSION 1.8.13

RUN apk add --no-cache \
  gcc \
  libc-dev \
  linux-headers \
  lua5.3-dev \
  make \
  openssl-dev \
  pcre-dev

RUN mkdir /haproxy
RUN wget -qO- https://www.haproxy.org/download/$(echo $HAPROXY_VERSION | sed -e 's/\.[^.]*$//')/src/haproxy-$HAPROXY_VERSION.tar.gz | tar xz -C /haproxy --strip-components=1
RUN make -C /haproxy -j$(nproc) all \
  TARGET=linux2628 \
  USE_LUA=1 LUA_INC=/usr/include/lua5.3 LUA_LIB=/usr/lib/lua5.3 \
  USE_OPENSSL=1 \
  USE_PCRE=1 PCREDIR= \
  USE_ZLIB=1

FROM alpine:3.8

RUN apk add --no-cache \
  lua5.3 \
  openssl \
  pcre

RUN addgroup -g 1042 haproxy \
  && adduser -u 1042 -G haproxy -s /bin/sh -D haproxy

ENV HAPROXY_CONFIG haproxy.cfg

RUN mkdir /etc/haproxy /var/lib/haproxy
COPY --from=builder /haproxy/haproxy /usr/sbin/haproxy
COPY --from=builder /haproxy/examples/errorfiles/* /etc/haproxy/errors/

# http://cbonte.github.io/haproxy-dconv/1.8/management.html#4
# "4. Stopping and restarting HAProxy"
# HAProxy supports a graceful and a hard stop. The hard stop is simple, when the
# SIGTERM signal is sent to the haproxy process, it immediately quits and all
# established connections are closed. The graceful stop is triggered when the
# SIGUSR1 signal is sent to the haproxy process. It consists in only unbinding
# from listening ports, but continue to process existing connections until they
# close. Once the last connection is closed, the process leaves.
# STOPSIGNAL SIGUSR1

CMD exec haproxy -db -W -f /etc/haproxy/$HAPROXY_CONFIG
