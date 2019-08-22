FROM jupyter/minimal-notebook:0c84b71d9f3d

USER root

#
# Additional packages
#

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
         curl dnsutils jq openjdk-8-jre vim zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -Lo /tmp/xoStitch.deb \
      https://github.com/ChameleonCloud/xo-stitch/releases/download/v0.1-alpha/xoStitch.deb \
    && dpkg -i /tmp/xoStitch.deb \
    && rm -f /tmp/xoStitch.deb

#
# JupyterLab extensions
# Note: JupyterLab is quite unstable at the moment (not 1.x yet) and as such
# whenever a new minor version of JupyterLab is released, often the extensions
# need to be updated.
#

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@1.0
RUN jupyter labextension install @jupyterlab/latex@1.0.0
RUN jupyter labextension install @chameleoncloud/jupyterlab-theme-extension@1.0.0
RUN jupyter labextension install @chameleoncloud/jupyterlab_swift@1.0.0
RUN jupyter labextension install @chameleoncloud/jupyterlab_zenodo@0.1.1

#
# Notebook dependencies
# (Includes Notebook server extension dependencies)
#

COPY requirements.txt /tmp/singleuser-requirements.txt
RUN python3 -m pip install --no-cache -r /tmp/singleuser-requirements.txt \
  && rm -f /tmp/singleuser-requirements.txt

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

USER $NB_USER
