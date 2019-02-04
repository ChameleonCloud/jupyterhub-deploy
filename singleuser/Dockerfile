FROM jupyter/minimal-notebook:610bb8b938db

USER root

#
# Additional packages
#

RUN apt-get update && apt-get install -yq --no-install-recommends \
    curl \
    dnsutils \
    vim \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# JupyterLab extensions
# Note: JupyterLab is quite unstable at the moment (not 1.x yet) and as such
# whenever a new minor version of JupyterLab is released, often the extensions
# need to be updated.
#

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.37
RUN jupyter labextension install @jupyter/jupyterlab-git@0.4
RUN jupyter labextension install @jupyterlab/latex@0.5
RUN jupyter labextension install @chameleoncloud/jupyterlab_swift@0.2.0

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

RUN jupyter nbextension enable --py widgetsnbextension
RUN jupyter serverextension enable --py jupyterlab_git

#
# Notebook start hooks
#

RUN apt-get update && apt-get install -yq openssh-client rsync \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY start-notebook.d/* /usr/local/bin/start-notebook.d/
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/
# Everything in serverroot gets copied to the user's working directory on start
RUN mkdir -p /etc/jupyter/serverroot
COPY serverroot/* /etc/jupyter/serverroot/

USER $NB_USER
