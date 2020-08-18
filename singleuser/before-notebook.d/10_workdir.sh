# Link original home directory to renamed one.
# This helps `docker exec` continue to work (the container's launch dir
# is /home/jovyan by default) and is really the only reason we do this.
if [[ "$NB_USER" != jovyan ]]; then
  ln -sf "/home/$NB_USER" /home/jovyan
fi

# Fix permissions on entire home directory
chown -R "$NB_USER:" "/home/$NB_USER"
