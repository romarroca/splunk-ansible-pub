IMAGE ?= splunk-ansible-ctrl
DOCKERFILE ?= docker/ansible-controller.Dockerfile
WORKDIR ?= /splunk-ansible
CONTAINER ?= ansible-ctrl

.PHONY: docker-build docker-shell

docker-build:
	docker build -t $(IMAGE) -f $(DOCKERFILE) .

docker-shell:
	docker run --rm -it --name $(CONTAINER) \
		-v "$(PWD):$(WORKDIR)" \
		-w $(WORKDIR) \
		$(IMAGE)
