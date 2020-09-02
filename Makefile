.SILENT:

.PHONY: build push

UID := 210
GID := 210
USERNAME := teneo

IMAGE_TAG := registry.docker.libis.be/teneo/ingester:latest

all: build push

build:
	docker build -t $(IMAGE_TAG) --build-arg UID=$(UID) --build-arg GID=$(GID) --build-arg USERNAME=$(USERNAME) .

push:
	docker push $(IMAGE_TAG)

