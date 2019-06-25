# Copy examples and other "first launch" files over.
rsync -aq /etc/jupyter/serverroot/ /work/

# Check out community notebooks
notebooks_dir=/work/notebooks
if [[ ! -d "$notebooks_dir" ]]; then
  git clone https://github.com/chameleoncloud/notebooks.git "$notebooks_dir"
else
  (cd "$notebooks_dir" && git stash && git pull && git stash pop || true)
fi

# Our volume mount is at the root directory, link it in to the user's
# home directory for convenience.
rm -rf /home/jovyan/work && ln -s /work /home/jovyan/work

# MAXINE: added the lines below to clone a git repo into the work directory
experiment_dir=~/work/experiments

if [[ "$IS_IMPORTED" = "yes" ]]; then
   cd work 
   git clone $CLONE_URL
   cd ..
fi
