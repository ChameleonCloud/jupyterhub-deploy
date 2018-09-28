#!/usr/bin/env bash
home_dir="$(getent passwd "$NB_USER" | cut -f6 -d:)"
key_file="$home_dir/.ssh/id_rsa"

declare -a cmd=(ssh-keygen -f "$key_file" -t rsa -b 4096 -C "$NB_USER@jupyterhub" -N "")

# Generate SSH key
if [ $(id -u) == 0 ] ; then
  sudo -u "$NB_USER" "${cmd[@]}"
else
  "${cmd[@]}"
fi

chmod 400 "$key_file"
