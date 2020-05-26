#!/usr/bin/env sh

set -e

: "${ZT_NETWORK_ID?"Need to set ZT_NETWORK_ID"}"

# set default path
: "${CADDYFILE_PATH:=/etc/caddy/Caddyfile}"

if [ -n "$ZT_IDENTITY_PUBLIC" ]; then
	echo "$ZT_IDENTITY_PUBLIC" > /var/lib/zerotier-one/identity.public
elif [ -n "$ZT_IDENTITY_PUBLIC_PATH" ]; then
	cp "$ZT_IDENTITY_PUBLIC" /var/lib/zerotier-one/identity.public
fi

if [ -n "$ZT_IDENTITY_SECRET" ]; then
	echo "$ZT_IDENTITY_SECRET" > /var/lib/zerotier-one/identity.secret
elif [ -n "$ZT_IDENTITY_SECRET_PATH" ]; then
	cp "$ZT_IDENTITY_SECRET_PATH" /var/lib/zerotier-one/identity.secret
fi

if [ ! -f /var/lib/zerotier-one/identity.public ]; then
    echo "/var/lib/zerotier-one/identity.public not found!"
    exit 1
fi

if [ ! -f /var/lib/zerotier-one/identity.secret ]; then
    echo "/var/lib/zerotier-one/identity.secret not found!"
    exit 1
fi

if [ ! -f "$CADDYFILE_PATH" ]; then
    echo "$CADDYFILE_PATH not found!"
    exit 1
fi

if [ "$ZT_NETWORK_ID" = "8056c2e21c000001" ]; then
	echo "WARNING! You are connecting to ZeroTier's Earth network!"
	echo "If you join this or any other public network, make sure your computer is up to date on all security patches and you've stopped, locally firewalled, or password protected all services on your system that listen for outside connections."
fi

# start zerotier and daemonize
zerotier-one -d -p0

# let zerotier daemon startup
sleep 1

echo "ZeroTier identity: $(zerotier-cli info -j | jq -r .address)"

# TODO: allow for multiple networks
zerotier-cli join "$ZT_NETWORK_ID"

while /bin/true; do
	addr=$(zerotier-cli listnetworks -j | jq -r '.[0].assignedAddresses | join(", ")')
    if [ "$addr" != "" ]; then
    	echo "ZeroTier assigned addresses: $addr"
    	echo "starting Caddy server..."
		exec caddy run --adapter caddyfile --config "$CADDYFILE_PATH"
    fi
    echo "waiting for ZeroTier..."
    sleep 2
done
