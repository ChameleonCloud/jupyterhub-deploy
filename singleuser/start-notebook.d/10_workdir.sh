# Copy examples and other "first launch" files over.
rsync -aq /etc/jupyter/serverroot/ /work/

# Our volume mount is at the root directory, link it in to the user's
# home directory for convenience.
rm -rf /home/jovyan/work && ln -s /work /home/jovyan/work
