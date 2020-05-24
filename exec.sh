#!/usr/bin/env sh

set -e

: "${ZT_NETWORK_ID?"Need to set ZT_NETWORK_ID"}"

if [ ! -f /var/lib/zerotier-one/identity.public ]; then
    echo "/var/lib/zerotier-one/identity.public not found!"
    exit 1
fi

if [ ! -f /var/lib/zerotier-one/identity.secret ]; then
    echo "/var/lib/zerotier-one/identity.secret not found!"
    exit 1
fi

if [ ! -f /etc/caddy/Caddyfile ]; then
    echo "/etc/caddy/Caddyfile not found!"
    exit 1
fi

zerotier-one -d -p0

# let zerotier daemon startup
sleep 1

# TODO: allow for multiple networks
zerotier-cli join "$ZT_NETWORK_ID"

while /bin/true; do
	addr=$(zerotier-cli listnetworks -j | jq -r .[0].assignedAddresses[0])
    if [ "$addr" != "null" ]; then
    	echo "ZeroTier address: $addr"
    	echo "starting Caddy server..."
		exec caddy run --watch --adapter caddyfile --config /etc/caddy/Caddyfile
    fi
    echo "waiting for ZeroTier..."
    sleep 2
done
