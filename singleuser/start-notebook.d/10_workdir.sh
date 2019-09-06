workdir=/work

git_fetch_latest() {
  local repo="$1"
  # Gracefully fail
  (cd "$repo" && git stash && git pull && git stash pop) || {
    echo "Failed to pull latest changes from remote"
  }
}

setup_default_server() {
  # Copy examples and other "first launch" files over.
  rsync -aq /etc/jupyter/serverroot/ $workdir/

  notebooks_dir=$workdir/notebooks
  if [[ ! -d "$notebooks_dir" ]]; then
    git clone https://github.com/chameleoncloud/notebooks.git "$notebooks_dir"
  else
    git_fetch_latest "$notebooks_dir"
  fi
}

setup_experiment_server() {
  if [[ -z "$SRC_PATH" ]]; then
    echo "No source path defined!"
    exit 1
  fi

  case "$IMPORT_SRC" in
    git)
      if [[ ! -d "$workdir/.git" ]]; then
        git clone https://github.com/$SRC_PATH $workdir
      else
        git_fetch_latest $workdir
      fi
      ;;
    zenodo)
      wget https://zenodo.org/$SRC_PATH
      unzip '*.zip' -d $workdir
      rm *.zip
      ;;
    *)
      echo "Unknown import source '$IMPORT_SRC'. Supported values are 'git', 'zenodo'"
      exit 1
      ;;
  esac

  pushd $workdir
  if [[ -f "requirements.txt" ]]; then
     pip install -r "requirements.txt"
  fi
  popd
}

if [[ -z "${IMPORT_SRC+x}" ]]; then
  setup_default_server
else
  setup_experiment_server
fi

# Our volume mount is at the root directory, link it in to the user's
# home directory for convenience.
rm -rf /home/jovyan/work && ln -s $workdir /home/jovyan/work
