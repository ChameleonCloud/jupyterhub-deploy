# Generate SSH key for user; this can be imported into GitHub
# to serve as a deploy key, or uploaded as an OpenStack/AWS keypair.
key_file="/data/.ssh/id_rsa"

if [[ ! -f "$key_file" ]]; then
  mkdir -p "$(dirname "$key_file")"
  ssh-keygen -f "$key_file" -t rsa -b 4096 -C "$NB_USER@jupyterhub" -N ""
  chmod 400 "$key_file"
fi

# For backwards compatibility, also copy to /work.
work_key_file="/work/.ssh/id_rsa"
if [[ ! -f "$work_key_file" ]]; then
  mkdir -p "$(dirname "$work_key_file")"
  cp "$key_file" "$work_key_file"
fi
