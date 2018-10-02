ARG BASE_IMAGE
FROM $BASE_IMAGE

USER root

#
# JupyterLab extensions
#

# https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager#version-compatibility
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.37

RUN apt-get update \
  && apt-get install -yq texlive-xetex \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && jupyter labextension install @jupyterlab/latex

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
