set -x

workdir=/work
expdir=/exp
archive=/tmp/_archive

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

setup_default_server() {
  # Copy examples and other "first launch" files over.
  rsync -aq /etc/jupyter/serverroot/ $workdir/
  git_fetch https://github.com/chameleoncloud/notebooks.git $workdir/notebooks
}

setup_experiment_server() {
  if [[ "${IMPORT_REPO:-}" == "git" ]]; then
    git_fetch "$IMPORT_URL" $workdir
  else
    wget -P $workdir -O $archive "$IMPORT_URL"
  fi
  unset IMPORT_URL
  unset IMPORT_REPO

  pushd $workdir
  if [[ -f $archive ]]; then
    unzip -d $workdir $archive || tar -C $workdir -xf $archive \
      && rm $archive || echo "Failed to extract $archive"
  fi
  if [[ -f requirements.txt ]]; then
    echo "Installing pip requirements"
    pip install -r requirements.txt
  fi
  popd

  # TODO: use separate experiment directory for named servers?
  # rm -rf /home/jovyan/exp && ln -s $expdir /home/jovyan/exp
}

if [[ -n "${IMPORT_URL}" ]]; then
  setup_experiment_server
else
  setup_default_server
fi

# Our volume mount is at the root directory, link it in to the user's
# home directory for convenience.
rm -rf /home/jovyan/work && ln -s $workdir /home/jovyan/work

set +x
