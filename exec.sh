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

if [ "$ZT_NETWORK_ID" = "8056c2e21c000001" ]; then
	echo "WARNING! You are connecting to ZeroTier's Earth network!"
	echo "If you join this or any other public network, make sure your computer is up to date on all security patches and you've stopped, locally firewalled, or password protected all services on your system that listen for outside connections."
fi

zerotier-one -d -p0

# let zerotier daemon startup
sleep 1

# TODO: allow for multiple networks
zerotier-cli join "$ZT_NETWORK_ID"

while /bin/true; do
	addr=$(zerotier-cli listnetworks -j | jq -r '.[0].assignedAddresses | join(", ")')
    if [ "$addr" != "null" ]; then
    	echo "ZeroTier assigned addresses: $addr"
    	echo "starting Caddy server..."
		exec caddy run --watch --adapter caddyfile --config /etc/caddy/Caddyfile
    fi
    echo "waiting for ZeroTier..."
    sleep 2
done
