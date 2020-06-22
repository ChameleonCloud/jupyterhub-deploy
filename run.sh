#!/usr/bin/env bash

DIR="$(cd $(dirname ${BASH_SOURCE[0]}) 2>&1 >/dev/null && pwd)"

EXTENSION_DIR=
SINGLEUSER=0

secret_dir="$DIR/secrets"

usage() {
  cat <<USAGE
Usage: run.sh [--single] [-e|--extension-dir DIR]


USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--extension-dir)
      shift
      EXTENSION_DIR="$1"
      ;;
    --single)
      SINGLEUSER=1
      ;;
    *)
      usage
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
  "${run_cmd[@]}"
else
  if [[ -n "$EXTENSION_DIR" ]]; then
    export JUPYTERHUB_EXTVOL="$EXTENSION_DIR"
    export JUPYTERHUB_CMD="bash"
  fi
  docker-compose up
fi
