include .env

JUPYTERHUB_SINGLEUSER_VERSION = $(shell git log -n1 --format=%h -- singleuser)
JUPYTERHUB_VERSION = $(shell git log -n1 --format=%h -- hub)

REGISTRY := docker.chameleoncloud.org

# Hub notebook targets

.PHONY: hub-build
hub-build: hub/cull_idle_servers.py
	docker build -t $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) hub
	# Tag for local development
	docker tag $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) $(JUPYTERHUB_IMAGE):dev

.PHONY: hub-publish
hub-publish:
	docker tag $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) \
		         $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)
	docker push $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)

.PHONY: hub-publish-latest
hub-publish-latest:
	docker tag $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) \
				$(REGISTRY)/$(JUPYTERHUB_IMAGE):latest
	docker push $(REGISTRY)/$(JUPYTERHUB_IMAGE):latest

# Single user notebook targets

.PHONY: singleuser-build
singleuser-build:
	docker build -t $(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION) singleuser
	# Tag for local development
	docker tag $(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION) $(JUPYTERHUB_SINGLEUSER_IMAGE):dev

.PHONY: singleuser-publish
singleuser-publish:
	docker tag $(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION) \
		         $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION)
	docker push $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION)

.PHONY: singleuser-publish-latest
singleuser-publish-latest:
	docker tag $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE):$(JUPYTERHUB_SINGLEUSER_VERSION) \
				$(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE):latest
	docker push $(REGISTRY)/$(JUPYTERHUB_SINGLEUSER_IMAGE):latest
