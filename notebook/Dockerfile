# Python 3.8
# Notebook 6.2.0
# JupyterLab 3.0.12
# JupyterHub 1.3.0
FROM jupyter/minimal-notebook:4d9c9bd9ced0 as base

USER root

#
# Additional packages
#

RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
  curl dnsutils jq moreutils openjdk-8-jre vim zip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN curl -Lo /tmp/xoStitch.deb \
  https://github.com/ChameleonCloud/xo-stitch/releases/download/v0.2/xoStitch-v0.2.deb \
  && dpkg -i /tmp/xoStitch.deb \
  && rm -f /tmp/xoStitch.deb

#
# JupyterLab extensions
#
# NOTE(jason): JupyterLab is in an active development state, so
# whenever a new minor version of JupyterLab is released, often the extensions
# need to be updated.
#

# RUN jupyter labextension install @chameleoncloud/jupyterlab-theme-extension@2.0.0

#
# Notebook dependencies
# (Includes Notebook server extension dependencies)
#

COPY requirements.txt /tmp/notebook-requirements.txt

ARG openstack_release=train
RUN python3 -m pip install --no-cache -r /tmp/notebook-requirements.txt \
  && rm -f /tmp/notebook-requirements.txt

#
# Enable server extensions
#

USER $NB_USER

RUN python3 -m bash_kernel.install

FROM base as chameleon

USER root

RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
  python3-dev libffi-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY chi-requirements.txt /tmp/chi-requirements.txt

ARG openstack_release=train
RUN curl -Sso /upper-constraints.txt "https://raw.githubusercontent.com/openstack/requirements/stable/${openstack_release}/upper-constraints.txt" \
  && python3 -m pip install --no-cache -r /tmp/chi-requirements.txt -c /upper-constraints.txt \
  && rm -f /tmp/chi-requirements.txt /upper-constraints.txt \
  && python3 -m pip install --no-cache \
  git+https://github.com/ChameleonCloud/python-blazarclient@chameleoncloud/stable/train#egg=python-blazarclient \
  git+https://github.com/ChameleonCloud/python-heatclient@stable/rocky#egg=python-heatclient

# FIXME(jason): this should not be necessary, it should automatically be enabled on install.
RUN jupyter serverextension enable jupyterlab_chameleon

#
# Notebook start hooks
#

RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
  openssh-client rsync \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
COPY start-notebook.d/* /usr/local/bin/start-notebook.d/
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
# Everything in serverroot gets copied to the user's working directory on start
RUN mkdir -p /etc/jupyter/serverroot
COPY serverroot/* /etc/jupyter/serverroot/

COPY bashrc.d /home/$NB_USER/.bashrc.d
COPY start-notebook-dev.sh /usr/local/bin/

USER $NB_USER
