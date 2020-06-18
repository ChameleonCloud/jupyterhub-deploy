#!/usr/bin/env bash

export GRANT_SUDO=yes
export CHOWN_EXTRA=/work
export CHOWN_EXTRA_ARGS=-R
export JUPYTER_ENABLE_LAB=yes 

start-notebook.sh --app-dir=/home/jovyan/.jupyter/lab \
  --ZenodoConfig.dev=True \
  --ZenodoConfig.access_token="${ZENODO_DEFAULT_ACCESS_TOKEN:-fake}" \
  "$@"
