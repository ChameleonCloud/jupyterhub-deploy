include .env

JUPYTERHUB_SINGLEUSER_WORKDIR ?= $(PWD)
ifdef JUPYTERHUB_SINGLEUSER_EXTDIR
JUPYTERHUB_SINGLEUSER_EXTRA := --mount "type=bind,src=$(JUPYTERHUB_SINGLEUSER_EXTDIR),target=/ext"
else ifdef JUPYTERHUB_SINGLEUSER_EXTVOL
JUPYTERHUB_SINGLEUSER_EXTRA := --mount "type=volume,src=$(JUPYTERHUB_SINGLEUSER_EXTVOL),target=/ext"
endif

JUPYTERHUB_SINGLEUSER_VERSION = $(shell git log -n1 --format=%h -- singleuser)
JUPYTERHUB_VERSION = $(shell git log -n1 --format=%h -- hub)

REGISTRY := docker.chameleoncloud.org

# Hub notebook targets

.PHONY: hub-build
hub-build: hub/cull_idle_servers.py
	docker build -t $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) hub
	# Tag for local development
	docker tag $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) $(JUPYTERHUB_IMAGE):dev

hub/cull_idle_servers.py:
	curl -L -o $@ \
		https://raw.githubusercontent.com/jupyterhub/jupyterhub/master/examples/cull-idle/cull_idle_servers.py

.PHONY: hub-start
hub-start: check-files network volumes
	docker-compose up

.PHONY: hub-publish
hub-publish:
	docker tag $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) \
		         $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)
	docker push $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)

# Single user notebook targets

.PHONY: singleuser-build
singleuser-build:
	docker build -t $(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION) singleuser
	# Tag for local development
	docker tag $(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION) $(JUPYTERHUB_SINGLEUSER_IMAGE):dev

.PHONY: singleuser-start
singleuser-start:
	docker run --rm --interactive --tty \
		--publish 8888:8888 \
		--user root \
		--mount "type=bind,src=$(JUPYTERHUB_SINGLEUSER_WORKDIR),target=/work" \
		--workdir "/work" \
		$(JUPYTERHUB_SINGLEUSER_EXTRA) \
		$(JUPYTERHUB_SINGLEUSER_IMAGE):dev

.PHONY: singleuser-shell
singleuser-shell:
	docker run --rm --interactive --tty \
		--publish 8888:8888 \
		--user root \
		--mount "type=bind,src=$(JUPYTERHUB_SINGLEUSER_WORKDIR),target=/work" \
		--workdir "/work" \
		$(JUPYTERHUB_SINGLEUSER_EXTRA) \
		$(JUPYTERHUB_SINGLEUSER_IMAGE):dev \
		bash

.PHONY: singleuser-publish
singleuser-publish:
	docker tag $(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION) \
		         $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION)
	docker push $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION)

# Local development helper targets

.PHONY: network
network:
	@docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)

.PHONY: volumes
volumes:
	@docker volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DATA_VOLUME_HOST)
	@docker volume inspect $(DB_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DB_VOLUME_HOST)

secrets:
	mkdir -p $@

secrets/jupyterhub.env: secrets
	@echo "Generating JupyterHub encryption keys in $@"
	@echo "JUPYTERHUB_CRYPT_KEY=$(shell openssl rand -hex 32)" > $@

secrets/mysql.env: secrets
	@echo "Generating mysql passwords in $@"
	@echo "MYSQL_ROOT_PASSWORD=$(shell openssl rand -hex 32)" > $@
	@echo "MYSQL_USER=jupyterhub" >> $@
	@echo "MYSQL_PASSWORD=$(shell openssl rand -hex 32)" >> $@
	@echo "MYSQL_DATABASE=jupyterhub" >> $@

.PHONY: check-files
check-files: secrets/jupyterhub.env secrets/mysql.env
