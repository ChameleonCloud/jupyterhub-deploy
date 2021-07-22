# Generate SSH key for user; this can be imported into GitHub
# to serve as a deploy key, or uploaded as an OpenStack/AWS keypair.
key_file="/data/.ssh/id_rsa"

if [[ ! -f "$key_file" ]]; then
  mkdir -p "$(dirname "$key_file")"
  ssh-keygen -f "$key_file" -t rsa -m pem -b 4096 -C "$NB_USER@jupyterhub" -N ""
  chmod 400 "$key_file"
elif grep -q 'BEGIN OPENSSH PRIVATE KEY' "$key_file"; then
  # We used to generate key files with rfc4716, but older
  # versions of Paramiko (<2.7) do not support it.
  # https://github.com/paramiko/paramiko/issues/602
  # This is a trick to "update" the key file by setting the
  # passphrase to the same value, but it exports as PEM.
  ssh-keygen -p -N "" -m pem -f "$key_file"
fi

# For backwards compatibility, also copy to /work.
work_key_file="/work/.ssh/id_rsa"
if [[ ! -f "$work_key_file" ]]; then
  mkdir -p "$(dirname "$work_key_file")"
  cp "$key_file" "$work_key_file"
  cp "${key_file}.pub" "${work_key_file}.pub"
fi
