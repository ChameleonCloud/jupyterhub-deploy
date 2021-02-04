#!/usr/bin/env bash

declare -a cmd=(jupyterhub)
if [[ -n "$NOTEBOOK_EXTENSION" ]]; then
  cmd+=(--ChameleonSpawner.extra_volumes={\'$NOTEBOOK_EXTENSION\':\'/ext\'})
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
  echo -e "Watching:\n$files"
  entr -nr "${cmd[@]}" <<<"$files"
else
  "${cmd[@]}"
fi
