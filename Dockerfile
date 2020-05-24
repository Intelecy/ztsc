ARG ALPINE_VERSION=3.11
ARG CADDDY_VERSION=2.0.0

FROM caddy:${CADDDY_VERSION}-alpine as caddy

FROM alpine:${ALPINE_VERSION} as zt-builder

ARG ZT_VERSION=1.4.6

RUN apk add --update alpine-sdk linux-headers \
  && git clone --depth 1 --branch ${ZT_VERSION} https://github.com/zerotier/ZeroTierOne.git /src \
  && cd /src \
  && make -f make-linux.mk

FROM alpine:${ALPINE_VERSION}

LABEL maintainer="jonathan.camp@intelecy.com"

RUN apk add --update --no-cache libc6-compat libstdc++ nss-tools jq

COPY --from=zt-builder /src/zerotier-one /usr/sbin/

RUN mkdir -p /var/lib/zerotier-one \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

ADD exec.sh /usr/local/bin

CMD ["exec.sh"]
