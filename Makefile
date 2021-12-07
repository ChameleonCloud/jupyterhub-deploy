include .env

NOTEBOOK_VERSION = $(shell git log -n1 --format=%h -- notebook)
JUPYTERHUB_VERSION = $(shell git log -n1 --format=%h -- hub)
BUILD_FLAGS ?=

REGISTRY := docker.chameleoncloud.org

# Hub notebook targets
.PHONY: hub-build
hub-build: hub/cull_idle_servers.py
	# Ensure release builds are always built for x86
	docker build --platform linux/amd64 $(BUILD_FLAGS) -t $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) --target release hub
	# Tag for local development
	docker build $(BUILD_FLAGS) -t $(JUPYTERHUB_IMAGE):dev --target dev hub

.PHONY: hub-publish
hub-publish:
	docker tag $(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION) \
		         $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)
	docker push $(REGISTRY)/$(JUPYTERHUB_IMAGE):$(JUPYTERHUB_VERSION)

hub/cull_idle_servers.py:
	wget https://raw.githubusercontent.com/jupyterhub/jupyterhub-idle-culler/master/jupyterhub_idle_culler/__init__.py -O hub/cull_idle_servers.py

# Notebook server targets

.PHONY: notebook-build
notebook-build:
	# Ensure release builds are always built for x86
	docker build --platform linux/amd64 $(BUILD_FLAGS) -t $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) notebook
	# Tag for local development
	docker tag $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) $(NOTEBOOK_IMAGE):dev

.PHONY: notebook-publish
notebook-publish:
	docker tag $(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION) \
		         $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION)
	docker push $(REGISTRY)/$(NOTEBOOK_IMAGE):$(NOTEBOOK_VERSION)

.PHONY: notebook-publish-base
notebook-publish-base:
	docker build --target base $(BUILD_FLAGS) -t $(REGISTRY)/$(NOTEBOOK_IMAGE):base notebook
	docker push $(REGISTRY)/$(NOTEBOOK_IMAGE):base
