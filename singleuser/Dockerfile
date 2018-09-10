ARG DOCKER_NOTEBOOK_IMAGE
FROM $DOCKER_NOTEBOOK_IMAGE

ARG JUPYTERHUB_VERSION
RUN python3 -m pip install --no-cache \
  jupyterhub==$JUPYTERHUB_VERSION

# Install important OpenStack clients and libraries
COPY requirements.txt ./
RUN python3 -m pip install --no-cache -r requirements.txt

# Don't change back to $NB_UID - we need to launch as root for the sudo
# Capabilities to be set up properly
USER root
ENV GRANT_SUDO=yes
