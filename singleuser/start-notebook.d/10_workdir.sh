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

# MAXINE: added the following 7 lines that're probably broken
experiment_dir=~/work/experiments
git_repo=https://github.com/eka-foundation/numerical-computing-is-fun.git

if [[ "$IS_IMPORTED" = "yes" ]]; then
   cd work 
   git clone $git_repo
   cd ..
fi
