include .env

JUPYTERHUB_SINGLEUSER_WORKDIR ?= $(PWD)

REGISTRY := docker.chameleoncloud.org

# Hub notebook targets

.PHONY: hub-build
hub-build:
	docker build -t $(JUPYTERHUB_IMAGE) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		hub

.PHONY: hub-start
hub-start: check-files network volumes
	docker-compose up

.PHONY: hub-publish
hub-publish:
	docker tag $(JUPYTERHUB_IMAGE) $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)
	docker push $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)

# Single user notebook targets

.PHONY: singleuser-build
singleuser-build:
	docker pull $(JUPYTERHUB_SINGLEUSER_BASE_IMAGE)
	docker build -t $(JUPYTERHUB_SINGLEUSER_IMAGE) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		--build-arg BASE_IMAGE=$(JUPYTERHUB_SINGLEUSER_BASE_IMAGE) \
		--build-arg PYTHON_CHI_VERSION=$(PYTHON_CHI_VERSION) \
		singleuser

.PHONY: singleuser-start
singleuser-start:
	docker run --rm --publish 8888:8888 \
		--user root \
		--env GRANT_SUDO=yes \
		--env JUPYTER_ENABLE_LAB=yes \
		--env NB_USER=$(USER) \
		--mount "type=bind,src=$(JUPYTERHUB_SINGLEUSER_WORKDIR),target=/work" \
		--workdir "/work" \
		$(JUPYTERHUB_SINGLEUSER_IMAGE)

.PHONY: singleuser-publish
singleuser-publish:
	docker tag $(JUPYTERHUB_SINGLEUSER_IMAGE) $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE)
	docker push $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE)

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
