ARG DOCKER_NOTEBOOK_IMAGE
FROM $DOCKER_NOTEBOOK_IMAGE

ARG JUPYTERHUB_VERSION
RUN python3 -m pip install --no-cache \
  jupyterhub==$JUPYTERHUB_VERSION

# Install important OpenStack clients and libraries
RUN python3 -m pip install --no-cache \
  keystoneauth \
  gnocchiclient \
  python-blazarclient \
  python-cinderclient \
  python-glanceclient \
  python-heatclient \
  python-ironicclient \
  python-keystoneclient \
  python-neutronclient \
  python-novaclient \
  python-openstackclient \
  python-swiftclient

USER root

COPY python-chameleoncloud /opt/python-chameleoncloud
RUN cd /opt/python-chameleoncloud && python setup.py install

# Don't change back to $NB_UID - we need to launch as root for the sudo
# Capabilities to be set up properly
ENV GRANT_SUDO=yes
