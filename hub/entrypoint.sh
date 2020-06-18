#!/usr/bin/env bash

if [[ -d /ext ]]; then
  pushd /ext 2>/dev/null

  # Install Python extension code
  if [[ -f setup.py ]]; then
    pip list | grep -q /ext || pip install -e .
  fi

  popd 2>/dev/null
fi

"$@"
