include .env

.PHONY: network
network:
	@docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)

.PHONY: volumes
volumes:
	@docker volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DATA_VOLUME_HOST)
	@docker volume inspect $(DB_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DB_VOLUME_HOST)

.PHONY: certs
certs:
	openssl dhparam -dsaparam -out secrets/dhparam.pem 2048

userlist:
	@echo "Add usernames, one per line, to ./userlist, such as:"
	@echo "    zoe admin"
	@echo "    wash"
	@exit 1

secrets/mysql.env:
	@echo "Generating mysql passwords in $@"
	@echo "MYSQL_ROOT_PASSWORD=$(shell openssl rand -hex 32)" > $@
	@echo "MYSQL_USER=jupyterhub" >> $@
	@echo "MYSQL_PASSWORD=$(shell openssl rand -hex 32)" >> $@
	@echo "MYSQL_DATABASE=jupyterhub" >> $@

.PHONY: check-files
check-files: secrets/mysql.env

.PHONY: pull
pull:
	docker pull $(DOCKER_NOTEBOOK_IMAGE)

.PHONY: notebook_image
notebook_image: pull singleuser/Dockerfile
	docker build -t $(LOCAL_NOTEBOOK_IMAGE) \
		--build-arg JUPYTERHUB_VERSION=$(JUPYTERHUB_VERSION) \
		--build-arg DOCKER_NOTEBOOK_IMAGE=$(DOCKER_NOTEBOOK_IMAGE) \
		singleuser

.PHONY: build
build: check-files network volumes
	docker-compose build
