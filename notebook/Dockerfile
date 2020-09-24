# Python 3.8
# Notebook 6.0.3
# JupyterLab 2.1.4
# JupyterHub 1.1.0
FROM jupyter/minimal-notebook:5197709e9f23

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

RUN jupyter labextension install --no-build @jupyter-widgets/jupyterlab-manager@2.0
RUN jupyter labextension install --no-build @chameleoncloud/jupyterlab-theme-extension@2.0.0
RUN jupyter labextension install --no-build @chameleoncloud/jupyterlab_swift@2.0.2
RUN jupyter labextension install --no-build @chameleoncloud/jupyterlab-chameleon@1.1.1
RUN jupyter lab build

#
# Notebook dependencies
# (Includes Notebook server extension dependencies)
#

COPY requirements.txt /tmp/notebook-requirements.txt

ARG openstack_release=train
RUN curl -Sso /upper-constraints.txt "https://raw.githubusercontent.com/openstack/requirements/stable/${openstack_release}/upper-constraints.txt" \
  && python3 -m pip install --no-cache -r /tmp/notebook-requirements.txt \
  && rm -f /tmp/notebook-requirements.txt

#
# Enable server extensions
#

RUN python3 -m bash_kernel.install
RUN jupyter nbextension enable --py widgetsnbextension

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
