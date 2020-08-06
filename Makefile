include .env

NOTEBOOK_VERSION = $(shell git log -n1 --format=%h -- singleuser)
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
	docker build -t $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) singleuser
	# Tag for local development
	docker tag $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) $(NOTEBOOK_IMAGE):dev

.PHONY: singleuser-publish
singleuser-publish:
	docker tag $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) \
		         $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION)
	docker push $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION)

.PHONY: singleuser-publish-latest
singleuser-publish-latest:
	docker tag $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) \
				$(REGISTRY)/$(NOTEBOOK_IMAGE):latest
	docker push $(REGISTRY)/$(NOTEBOOK_IMAGE):latest
