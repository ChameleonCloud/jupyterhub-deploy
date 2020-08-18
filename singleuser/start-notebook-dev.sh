#!/usr/bin/env bash

export GRANT_SUDO=yes
export CHOWN_EXTRA=/work
export CHOWN_EXTRA_ARGS=-R
export JUPYTER_ENABLE_LAB=yes

if [[ -f .env ]]; then
  set -a; source .env; set +a
fi

start-notebook.sh --app-dir=/home/jovyan/.jupyter/lab \
  --NotebookApp.password="$NOTEBOOK_PASSWORD" \
  --NotebookApp.tornado_settings={\'autoreload\':True} \
  --ZenodoConfig.dev=True \
  --ZenodoConfig.access_token="${ZENODO_DEFAULT_ACCESS_TOKEN:-fake}" \
  --watch \
  "$@"
