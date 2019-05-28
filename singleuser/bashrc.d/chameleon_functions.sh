#!/usr/bin/env bash
# A collection of useful functions for dealing with the Chameleon
# testbed via Bash. Most things are possible with the vanilla
# OpenStack CLI, but some things are a bit trickier; namely, getting
# resources currently associated with a lease.

# lease_list_floating_ips LEASE
#
# Lists the public floating IP addresses tied to a lease, if any.
#
# Example:
#   lease_list_floating_ips my-lease
#
lease_list_floating_ips() {
  lease_id="$1"
  local reservation_id=$(blazar lease-show "$lease_id" -f json \
    | jq -r '.reservations' \
    | jq -rs 'map(select(.resource_type=="virtual:floatingip"))[].id')

  openstack floating ip list --tags "reservation:$reservation_id" \
    -f value -c "Floating IP Address"
}
export -f lease_list_floating_ips

# lease_server_create_default_args LEASE
#
# Returns a list of arguments that can be fed in to an
# `openstack server create` call. Sets up some useful
# defaults like the reservation hint (required to launch
# with a lease) and the default support image / network.
#
# Example:
#   openstack server create $(lease_server_create_default_args my-lease) my-server
#
lease_server_create_default_args() {
  local lease="$1"
  declare -a local defaults=()

  defaults+=(--flavor baremetal)
  defaults+=(--image CC-CentOS7)

  local network_id=$(openstack network show sharednet1 -f value -c id)
  defaults+=(--nic net-id=$network_id)

  local reservation_id=$(blazar lease-show "$lease" -f json \
    | jq -r '.reservations' \
    | jq -rs 'map(select(.resource_type=="physical:host"))[].id')
  defaults+=(--hint reservation=$reservation_id)

  echo "${defaults[@]}"
}
export -f lease_server_create_default_args

# lease_list_reservations LEASE
#
# Returns a JSON-encoded list of reservation objects. This can be then filtered
# further by using `jq` or some other JSON processor. This function is provided
# because the "reservations" property of a lease is a nested JSON document,
# which can be confusing to deal with.
#
# Example:
#   # List all reservations of type "physical:host"
#   jq 'map(select(.resource_type="physical:host"))' <(lease_list_reservations my-lease)
#
lease_list_reservations() {
  local lease="$1"

  blazar lease-show "$lease" -f json \
    | jq -r '.reservations' | jq -s .
}
export -f lease_list_reservations

# key_pair_upload [KEYPAIR_NAME]
#
# Uploads the public key at ~/.ssh/id_rsa.pub as a new key pair titled
# KEYPAIR_NAME. Will first check if a key pair already exists with this name.
# Will not override existing key pairs.
#
# Example:
#   # Creates a new key pair 'my-keypair' with public key from ~/.ssh/id_rsa.pub
#   key_pair_upload my-keypair
#
key_pair_upload() {
  local keypair_name="${1:-$USER-jupyter}"

  openstack keypair show "$keypair_name" 2>/dev/null \
    || openstack keypair create --public-key "/work/.ssh/id_rsa.pub" "$keypair_name"
}
export -f key_pair_upload

# Wait helpers

wait_ssh() {
  local ip="$1"
  local timeout="${2:-300}"
  echo "Waiting up to $timeout seconds for SSH on $ip..."
  timeout $timeout bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 1; done' "$ip" 22 \
      && ssh-keyscan -H "$ip" 2>/dev/null >> ~/.ssh/known_hosts \
      && echo "SSH is running!"
}
export -f wait_ssh

wait_lease() {
  local lease="$1"
  local timeout="${2:-300}"
  echo "Waiting up to $timeout seconds for lease $lease to start..."
  timeout $timeout bash -c 'until [[ $(blazar lease-show $0 -f value -c status) == "ACTIVE" ]]; do sleep 1; done' "$lease" \
    && echo "Lease started successfully!"
}
export -f wait_lease

wait_instance() {
  local server="$1"
  local timeout="${2:-600}"
  echo "Waiting up to $timeout seconds for instance $server to start"
  timeout $timeout bash -c 'until [[ $(openstack server show $0 -f value -c status) == "ACTIVE" ]]; do sleep 1; done' "$server" \
    && echo "Instance created successfully!"
}
export -f wait_instance

wait_stack() {
  local stack="$1"
  local timeout="${2:-1800}"
  echo "Waiting up to $timeout seconds for stack $stack to start"
  timeout $timeout bash -c 'until [[ $(openstack stack show $0 -f value -c stack_status) == "CREATE_COMPLETE" ]]; do sleep 1; done' "$stack" \
    && echo "Stack started successfully!"
}
export -f wait_stack
