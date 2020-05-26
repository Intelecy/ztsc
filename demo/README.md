ZeroTier sidecar demo
======================

Docker Compose
--------------

1) Create a `.env` file with your ZeroTier network ID
2) Generate a new identity by running `make zerotier-identity`. Note: this will create two files `identity.public` and
`identity.secret`.
3) Start the demo and sidecar containers by running `make start`.
4) Log into the [ZeroTier dashboard](https://my.zerotier.com/network) and authorize the newly created member.
5) Verify in the docker compose logs that the `ztsc_1` container has received a ZeroTier IP address.
6) Access the demo service by using the ZeroTier IP address (port 80).

```
$ cat .env 
ZT_NETWORK_ID=0000000012345678

$ make zerotier-identity 
zerotier identity: 8f01205e00

$ make start
docker-compose -p ztsc-demo up --build
Building unsplash
...
Successfully built a95bbf88b5bb
Successfully tagged ztsc-demo_unsplash:latest
Recreating ztsc-demo_unsplash_1 ... done
Recreating ztsc-demo_ztsc_1     ... done
Attaching to ztsc-demo_unsplash_1, ztsc-demo_ztsc_1
unsplash_1  | 2020/05/25 06:55:01 listening on :8080
ztsc_1      | 200 join OK
ztsc_1      | waiting for ZeroTier...
ztsc_1      | waiting for ZeroTier...
ztsc_1      | ZeroTier assigned addresses: 10.147.18.92/24
ztsc_1      | starting Caddy server...
```

Nomad
-----