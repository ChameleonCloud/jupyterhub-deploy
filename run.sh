#!/usr/bin/env bash

DIR="$(cd $(dirname ${BASH_SOURCE[0]}) 2>&1 >/dev/null && pwd)"

NOTEBOOK_ONLY=0
NOTEBOOK_EXTENSION=
HUB_EXTENSION=
declare -a POSARGS=()

secret_dir="$DIR/secrets"

usage() {
  cat <<USAGE
Usage: run.sh [OPTIONS] [-- CMD]

Start a local development environment, either for JupyterHub or for
the configured Notebook server.

Options:
  -n, --notebook-only: start a Notebook server container instead of
    the full JupyterHub environment. The Notebook container
    is what is normally spawned by the hub, and can be
    useful for debugging or testing extensions to the
    Jupyter Notebook or JupyterLab applications. At container start
    time, the custom extension is installed via local pip installation,
    so that code changes are picked up automatically.

  --hub-extension: a directory that contains a local extension for
    JupyterHub.

  --notebook-extension: a directory that contains a local extension
    for the Notebook application.

  -w, --work-dir: a directory to mount as the working directory of the
    Notebook server (only valid when --notebook-only is used.)

  -h, --help: display this help text

Examples:
  # Run in hub mode (default)
  ./run.sh

  # Run just the Notebook with a local extension
  ./run.sh --notebook-only --notebook-extension ../path/to/extension

  # Run just the Notebook, but open a shell instead of the Notebook server
  ./run.sh --notebook-only -- bash
USAGE
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notebook-extension)
      shift
      NOTEBOOK_EXTENSION="$(realpath $1)"
      ;;
    --hub-extension)
      shift
      HUB_EXTENSION="$(realpath $1)"
      ;;
    -w|--work-dir)
      shift
      WORK_DIR="$(realpath $1)"
      ;;
    -n|--notebook-only)
      NOTEBOOK_ONLY=1
      ;;
    -h|--help)
      usage
      ;;
    --)
      IN_POSARGS=1
      ;;
    *)
      if [[ $IN_POSARGS -eq 1 ]]; then
        POSARGS+=($1)
      else
        usage
      fi
      ;;
  esac
  shift
done

if [[ ! -d "$secret_dir" ]]; then
  mkdir -p "$secret_dir"
  echo "Generating application secrets ..."
	cat >"$secret_dir/jupyterhub.env" <<EOF
JUPYTERHUB_CRYPT_KEY=$(openssl rand -hex 32)
EOF
  cat >"$secret_dir/mysql.env" <<EOF
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 32)
MYSQL_USER=jupyterhub
MYSQL_PASSWORD=$(openssl rand -hex 32)
MYSQL_DATABASE=jupyterhub
EOF
fi

set -a; source "$DIR/.env"; set +a

if [[ -n "$HUB_EXTENSION" ]]; then
  # Default hub extension otherwise docker-compose.yml mount config is invalid.
  HUB_EXTENSION="$(mktemp -d)"
fi

export HUB_EXTENSION
export NOTEBOOK_EXTENSION

docker network inspect "$DOCKER_NETWORK_NAME" >/dev/null \
  || docker network create "$DOCKER_NETWORK_NAME" >/dev/null

pushd "$DIR" >/dev/null

if [[ "$NOTEBOOK_ONLY" == "1" ]]; then
  declare -a run_cmd=(docker run --rm --interactive --tty \
    --name notebook \
    --net "$DOCKER_NETWORK_NAME" \
		--publish 8888:8888 \
		--user root \
		--mount "type=volume,src=jupyter-work,target=/work" \
		--workdir "/work")
  if [[ -n "$NOTEBOOK_EXTENSION" ]]; then
    run_cmd+=(--mount "type=bind,src=$NOTEBOOK_EXTENSION,target=/ext")
  fi
  run_cmd+=("$NOTEBOOK_IMAGE:dev")
  run_cmd+=("${POSARGS[@]:-start-notebook-dev.sh}")
  "${run_cmd[@]}"
else
  if [[ "$(uname)" == "Darwin" ]]; then
    export ENTR_INOTIFY_WORKAROUND=1
  fi
  docker-compose up
fi
