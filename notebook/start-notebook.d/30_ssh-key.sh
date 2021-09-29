# Generate SSH key for user; this can be imported into GitHub
# to serve as a deploy key, or uploaded as an OpenStack/AWS keypair.
key_file="/data/.ssh/id_rsa"

if [[ ! -f "$key_file" ]]; then
  mkdir -p "$(dirname "$key_file")"
  ssh-keygen -f "$key_file" -t rsa -m pem -b 4096 -C "$NB_USER@jupyterhub" -N ""
fi

# Ensure perms are OK
chmod 400 "$key_file"

# We used to generate key files with rfc4716, but older
# versions of Paramiko (<2.7) do not support it.
# https://github.com/paramiko/paramiko/issues/602
# This is a trick to "update" the key file by setting the
# passphrase to the same value, but it exports as PEM. 
if grep -q 'BEGIN OPENSSH PRIVATE KEY' "$key_file"; then
  cp -p "$key_file" "$key_file".bak
  ssh-keygen -p -N "" -m pem -f "$key_file"
fi

# Ensure pubkey matches generated key (in case user changed somehow)
ssh-keygen -y -f "$key_file" >"${key_file}.pub"

# For backwards compatibility, also copy to /work.
work_key_file="/work/.ssh/id_rsa"
if [[ ! -f "$work_key_file" ]]; then
  mkdir -p "$(dirname "$work_key_file")"
  cp "$key_file" "$work_key_file"
fi
ssh-keygen -y -f "$work_key_file" >"${work_key_file}.pub"

