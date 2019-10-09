workdir=/work

# Remove artifacts from mounting remote volume
rm -rf "$workdir/lost+found"

# Set up Git author config
git config --global user.name "$NB_USER"
git config --global user.email "$NB_USER@jupyter.chameleoncloud.org"

git_fetch_latest() {
  local repo="$1"
  # Gracefully fail
  (cd "$repo" && git stash && git pull && git stash pop) || {
    echo "Failed to pull latest changes from remote"
  }
}

git_fetch() {
  local remote="$1"
  local checkout="$2"

  if [[ ! -d "$checkout/.git" ]]; then
    git clone "$remote" $checkout
  else
    git_fetch_latest $checkout
  fi
}

zenodo_fetch() {
  local api_base="$1"
  local doi="$2"
  local dest="$3"

  local record_id=$(sed 's/^[0-9\.]*\/zenodo\.//' <<<"$doi")
  curl "$api_base/api/records/$record_id" \
    | jq -r .files[].links.self \
    | xargs -L1 wget -P $dest
}

setup_default_server() {
  # Copy examples and other "first launch" files over.
  rsync -aq /etc/jupyter/serverroot/ $workdir/
  git_fetch https://github.com/chameleoncloud/notebooks.git $workdir/notebooks
}

setup_experiment_server() {
  if [[ -z "$SRC_PATH" ]]; then
    echo "No source path defined!"
    exit 1
  fi

  case "$IMPORT_SRC" in
    git)
      # Allow any remote repository
      git_fetch $SRC_PATH $workdir
      ;;
    github)
      # Convenience; just specify repo name
      git_fetch https://github.com/$SRC_PATH $workdir
      ;;
    zenodo|zenodo_sandbox)
      if [[ "$IMPORT_SRC" == *sandbox ]]; then
        zenodo_fetch https://sandbox.zenodo.org "$SRC_PATH" $workdir
      else
        zenodo_fetch https://zenodo.org "$SRC_PATH" $workdir
      fi
      ;;
    *)
      echo "Unknown import source '$IMPORT_SRC'."
      echo "Supported values are 'git', 'github', 'zenodo', 'zenodo_sandbox'"
      exit 1
      ;;
  esac

  pushd $workdir
  if [[ -f "requirements.txt" ]]; then
     pip install -r "requirements.txt"
  fi
  unzip *.zip && rm *.zip || echo "No archives to unzip"
  # TODO: automatic tarball extraction
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
