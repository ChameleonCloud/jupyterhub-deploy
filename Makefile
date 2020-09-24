include .env

NOTEBOOK_VERSION = $(shell git log -n1 --format=%h -- notebook)
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

# Notebook server targets

.PHONY: notebook-build
notebook-build:
	docker build -t $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) notebook
	# Tag for local development
	docker tag $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) $(NOTEBOOK_IMAGE):dev

.PHONY: notebook-publish
notebook-publish:
	docker tag $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) \
		         $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION)
	docker push $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION)

.PHONY: notebook-publish-latest
notebook-publish-latest:
	docker tag $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) \
				$(REGISTRY)/$(NOTEBOOK_IMAGE):latest
	docker push $(REGISTRY)/$(NOTEBOOK_IMAGE):latest
