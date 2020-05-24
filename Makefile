DOCKER_REPO = "intelecy/ztsc"

default:

build:
	docker build -t $(DOCKER_REPO) .
