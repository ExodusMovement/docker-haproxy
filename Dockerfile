FROM alpine:3.8 as builder

ENV HAPROXY_VERSION 1.8.13

RUN apk add --no-cache \
  gcc \
  libc-dev \
  linux-headers \
  make \
  openssl-dev \
  pcre-dev

RUN mkdir /haproxy
RUN wget -qO- https://www.haproxy.org/download/$(echo $HAPROXY_VERSION | sed -e 's/\.[^.]*$//')/src/haproxy-$HAPROXY_VERSION.tar.gz | tar xz -C /haproxy --strip-components=1
RUN make -C /haproxy -j$(nproc) all TARGET=linux2628 USE_OPENSSL=1 USE_PCRE=1 PCREDIR= USE_ZLIB=1

FROM alpine:3.8

RUN apk add --no-cache \
  openssl \
  pcre

RUN addgroup -g 1042 haproxy \
  && adduser -u 1042 -G haproxy -s /bin/sh -D haproxy

ENV HAPROXY_CONFIG haproxy.cfg

RUN mkdir /etc/haproxy /var/lib/haproxy
COPY --from=builder /haproxy/haproxy /usr/sbin/haproxy
COPY --from=builder /haproxy/examples/errorfiles/* /etc/haproxy/errors/

CMD exec haproxy -db -W -f /etc/haproxy/$HAPROXY_CONFIG
