# Copy examples and other "first launch" files over.
rsync -aq /etc/jupyter/serverroot/ /work/

# Check out community notebooks if not imported
if [[ "$IS_IMPORTED" = "no" ]]; then
    notebooks_dir=/work/notebooks
    if [[ ! -d "$notebooks_dir" ]]; then
      git clone https://github.com/chameleoncloud/notebooks.git "$notebooks_dir"
    else
      (cd "$notebooks_dir" && git stash && git pull && git stash pop || true)
    fi

    # Our volume mount is at the root directory, link it in to the user's
    # home directory for convenience.
    rm -rf /home/jovyan/work && ln -s /work /home/jovyan/work
fi

# MAXINE: added the lines below to clone a git repo or zenodo zip file into the work directory
experiment_dir=~/work/experiments

if [[ "$IS_IMPORTED" = "yes" ]]; then
    cd work 
    # SRC_PATH is what comes after.com/ or .org/
    # For Git:
    if [[ "$IMPORT_SRC" = "git" ]]; then
        git clone http://github.com/$SRC_PATH
    # For Zenodo:
    else
        wget https://zenodo.org/$SRC_PATH
        unzip '*.zip'
        rm *.zip       
        tar xzf '*.tar.gz'
        rm *.tar.gz
    fi
    cd ..
fi
