# Generate SSH key for server instance; this can be imported into GitHub
# to serve as a deploy key, or uploaded as an OpenStack/AWS keypair.
key_file="/home/jovyan/.ssh/id_rsa"

if [[ ! -f "$key_file" ]]; then
  mkdir -p "$(dirname "$key_file")"
  ssh-keygen -f "$key_file" -t rsa -b 4096 -C "$NB_USER@jupyterhub" -N ""
  chmod 400 "$key_file"
fi
