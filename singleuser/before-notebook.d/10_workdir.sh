#!/usr/bin/env bash

# Link original home directory to renamed one.
# This helps `docker exec` continue to work (the container's launch dir
# is /home/jovyan by default) and is really the only reason we do this.
ln -s "/home/$NB_USER" /home/jovyan
