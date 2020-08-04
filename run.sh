#!/usr/bin/env bash

DIR="$(cd $(dirname ${BASH_SOURCE[0]}) 2>&1 >/dev/null && pwd)"

EXTENSION_DIR=
SINGLEUSER=0
declare -a POSARGS=()

secret_dir="$DIR/secrets"

usage() {
  cat <<USAGE
Usage: run.sh [--single] [-e] [-h] [--] CMD

Start a local development environment, either for JupyterHub or for
the configured single-user server.

Options:
  -s, --single: start a single-user container instead of the full
    JupyterHub environment. The single-user container
    is what is normally spawned by the hub, and can be
    useful for debugging or testing extensions to the
    Jupyter Notebook or JupyterLab applications. At container start
    time, the custom extension is installed via local pip installation,
    so that code changes are picked up automatically.

  -e, --extension-dir: a directory that contains a local extension,
    either to JupyterHub or to JupyterLab (when --single is used.)

  -w, --work-dir: a directory to mount as the working directory of the
    singleuser Notebook server (only valid when --single is used.)

  -h, --help: display this help text

Examples:
  # Run in hub mode (default)
  ./run.sh

  # Run in single-user mode with a local extension
  ./run.sh --single --extension-dir ../path/to/extension

  # Run in single-user mode, but open a shell instead of the Notebook server
  ./run.sh --single -- bash
USAGE
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--extension-dir)
      shift
      EXTENSION_DIR="$(realpath $1)"
      ;;
    -w|--work-dir)
      shift
      WORK_DIR="$(realpath $1)"
      ;;
    -s|--single)
      SINGLEUSER=1
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

docker network inspect "$DOCKER_NETWORK_NAME" >/dev/null \
  || docker network create "$DOCKER_NETWORK_NAME" >/dev/null

pushd "$DIR" >/dev/null

if [[ "$SINGLEUSER" == "1" ]]; then
  declare -a run_cmd=(docker run --rm --interactive --tty \
    --net "$DOCKER_NETWORK_NAME" \
		--publish 8888:8888 \
		--user root \
		--mount "type=volume,src=jupyter-work,target=/work" \
		--workdir "/work")
  if [[ -n "$EXTENSION_DIR" ]]; then
    run_cmd+=(--mount "type=bind,src=$EXTENSION_DIR,target=/ext")
  fi
  run_cmd+=("$JUPYTERHUB_SINGLEUSER_IMAGE:dev")
  run_cmd+=("${POSARGS[@]:-start-notebook-dev.sh}")
  "${run_cmd[@]}"
else
  if [[ -n "$EXTENSION_DIR" ]]; then
    export JUPYTERHUB_EXTVOL="$EXTENSION_DIR"
    export JUPYTERHUB_CMD="bash"
  fi
  docker-compose up
fi
