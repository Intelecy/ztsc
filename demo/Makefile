ZTSC = "intelecy/ztsc:latest"

default:

identity.secret:
	@docker run --rm -it $(ZTSC) zerotier-idtool generate > identity.secret

identity.public: identity.secret
	@cat identity.secret | docker run --rm -i $(ZTSC) zerotier-idtool getpublic /dev/stdin > identity.public

zerotier-identity: identity.secret identity.public
	@echo -n "zerotier identity: "
	@cut -d ':' -f 1 identity.public

start: zerotier-identity
	docker-compose -p ztsc-demo up --build
