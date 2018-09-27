ARG BASE_IMAGE
FROM $BASE_IMAGE

USER root

RUN apt-get update && apt-get install -yq --no-install-recommends \
       openssh-client \
       texlive-xetex \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG JUPYTERHUB_VERSION
RUN python3 -m pip install --no-cache \
  jupyterhub==$JUPYTERHUB_VERSION

# Install important OpenStack clients and libraries
COPY requirements.txt /tmp/singleuser-requirements.txt
RUN python3 -m pip install --no-cache -r /tmp/singleuser-requirements.txt \
  && rm -f /tmp/singleuser-requirements.txt

RUN jupyter labextension install \
  @jupyterlab/latex

ARG PYTHON_CHI_VERSION
RUN python3 -m pip install --no-cache \
  git+git://github.com/ChameleonCloud/python-chi.git@$PYTHON_CHI_VERSION#egg=python-chi

# Hooks are run automatically via the base-notebook's start.sh script
COPY before-notebook.d/* /usr/local/bin/before-notebook.d/

RUN mkdir -p /etc/jupyter/serverroot
COPY serverroot/* /etc/jupyter/serverroot/

USER $NB_USER
