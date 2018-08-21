include .env

.PHONY: network
network:
	@docker network inspect $(DOCKER_NETWORK_NAME) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK_NAME)

.PHONY: volumes
volumes:
	@docker volume inspect $(DATA_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DATA_VOLUME_HOST)
	@docker volume inspect $(DB_VOLUME_HOST) >/dev/null 2>&1 || docker volume create --name $(DB_VOLUME_HOST)

secrets/hub.key:
	@echo "Generating RSA(2048) private key in $@"
	@openssl genrsa 2048 > $@

secrets/hub.crt: secrets/hub.key
	@echo "Generating self-signed certificate in $@"
	@openssl req -new -x509 -nodes -days 365 -key $< -out $@ \
		-subj "/C=US/ST=Illinois/L=Chicago/O=Univesity of Chicago/CN=localhost"

secrets/dhparam.pem:
	@echo "Generating Diffie-Hellman params in $@"
	@openssl dhparam -dsaparam -out $@ 2048

secrets/jupyterhub.env:
	@echo "Generating JupyterHub encryption keys in $@"
	@echo "JUPYTERHUB_CRYPT_KEY=$(shell openssl rand -hex 32)" > $@

secrets/mysql.env:
	@echo "Generating mysql passwords in $@"
	@echo "MYSQL_ROOT_PASSWORD=$(shell openssl rand -hex 32)" > $@
	@echo "MYSQL_USER=jupyterhub" >> $@
	@echo "MYSQL_PASSWORD=$(shell openssl rand -hex 32)" >> $@
	@echo "MYSQL_DATABASE=jupyterhub" >> $@

userlist:
	@echo "Add usernames, one per line, to ./userlist, such as:"
	@echo "    zoe admin"
	@echo "    wash"
	@exit 1

.PHONY: check-files
check-files: secrets/dhparam.pem secrets/hub.crt secrets/hub.key secrets/jupyterhub.env secrets/mysql.env userlist

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

.PHONY: start
start:
	docker-compose up
