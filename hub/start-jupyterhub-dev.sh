#!/usr/bin/env bash

declare -a cmd=(jupyterhub)
if [[ -n "$NOTEBOOK_EXTENSION" ]]; then
  cmd+=(--ChameleonSpawner.extra_volumes={\'$NOTEBOOK_EXTENSION\':\'/ext\'})
  cmd+=(--ChameleonSpawner.args="--NotebookApp.tornado_settings={'autoreload':True}")
  cmd+=(--ChameleonSpawner.args="--autoreload")
fi
cmd+=(--ChameleonSpawner.resource_limits=False)

if [[ -d /ext ]]; then
  pushd /ext 2>/dev/null

  # Install Python extension code
  if [[ -f setup.py ]]; then
    pip list | grep -q /ext || pip install -e .
  fi
  # Super hacky... this accounts for the fact that pip install -e, which runs
  # the 'develop' setuptools task, doesn't copy/install data_files.
  if [[ -d ./share ]]; then
    echo "Installing data_files at ./share"
    cp -a ./share/* /usr/local/share/
  fi

  popd 2>/dev/null

  files="$(find /ext \( -path /ext/.git -o -path /ext/.tox -o -path /ext/build \) \
      -prune -false -o -name '*.py' -type f)"
  if [[ -n "$files" ]]; then
    echo -e "Watching:\n$files"
    entr -nr "${cmd[@]}" <<<"$files" || {
      echo "Failed to start watcher!"
      "${cmd[@]}"
    }
  else
    echo "No files to watch."
    "${cmd[@]}"
  fi
else
  "${cmd[@]}"
fi
