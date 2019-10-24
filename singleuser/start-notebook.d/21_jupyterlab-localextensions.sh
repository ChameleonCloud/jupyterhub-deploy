# Check for local extensions (dev-mode)
if [[ -d /ext ]]; then
  pushd /ext 2>/dev/null

  # Install server code, if any
  if [[ -f setup.py ]]; then
    python setup.py install
    # Hacky way to get the module name
    module_dir=$(find . -maxdepth 2 -name __init__.py | xargs dirname)
    jupyter serverextension enable --py ${module_dir##./} || {
      echo "Failed installing $module_dir as server extension!"
    }
  fi

  # Install client code, if any
  if [[ -d src ]]; then
    npm run build
    # Install local extension
    jupyter labextension list 2>/dev/null | grep /ext || {
      jupyter labextension install --app-dir=/home/jovyan/.jupyter/lab .
    }
  fi

  popd 2>/dev/null
fi
