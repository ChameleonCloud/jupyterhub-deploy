# Install wrapper functions that perform lazy refresh of access tokens.
# Access tokens have a relatively short TTL and can expire quickly.

_with_token() {
  access_token=$(curl -s -H"authorization: token $JUPYTERHUB_API_TOKEN" \
    "$JUPYTERHUB_API_URL/tokens" \
    | jq -r .access_token)
  if [[ "$access_token" != "null" ]]; then
    export OS_ACCESS_TOKEN="$access_token"
  fi
  command "$@"
}
export -f _with_token

alias openstack='_with_token openstack'
alias blazar='_with_token blazar'
