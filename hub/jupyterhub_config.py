# Copyright (c) University of Chicago.
# Distributed under the terms of the Modified BSD License.
#
# Configuration file for JupyterHub
# The following environment variables affect the configuration at runtime:
#
# DEBUG: (bool) whether to enable debug logging
# JUPYTERHUB_BASE_URL: (str) the full (public) base URL of the JupyterHub server
# DATA_VOLUME_CONTAINER: (str) the directory that JupyterHub will store its
#                        runtime data in
# DOCKER_VOLUME_DRIVER: (str) the name of the Docker volume driver to use when
#                       creating user work directories
# DOCKER_VOLUME_DRIVER_OPTS: (str) options, comma-separated "key=value" pairs,
#                            passed to the volume create command
# DOCKER_NOTEBOOK_IMAGE: (str) the name of the Docker image to spawn for users
# DOCKER_NETWORK_NAME: (str) the Docker network name
# KEYCLOAK_SERVER_URL: (str) the full base URL of the Keycloak server
# KEYCLOAK_REALM_NAME: (str) the Keycloak realm name to authenticate against
# KEYCLOAK_CLIENT_ID: (str) the Keycloak client ID
# KEYCLOAK_CLIENT_SECRET: (str) the Keycloak client secret
# OS_AUTH_URL: (str) the full base URL of the Keystone public endpoint
# OS_REGION_NAME: (str) an optional default Keystone region; if not set, the
#                 first detected region is used when looking up services
# OS_IDENTITY_PROVIDER: (str) the Keystone identity provider to use when logging
#                       in via federated authentication
# OS_PROTOCOL: (str) the Keystone federation protocol to use (openid, saml)
# MYSQL_HOST: (str) the JupyterHub MySQL hostname
# MYSQL_USER: (str) the JupyterHub MySQL user (must have grants to database)
# MYSQL_PASSWORD: (str) the JupyterHub MySQL user password
# MYSQL_DATABASE: (str) the JupyterHub MySQL database used to store data
# CHAMELEON_SHARING_PORTAL_UPLOAD_URL: (str) the full URL for the endpoint in
#                                      the Chameleon sharing portal that starts
#                                      the artifact creation flow.
# CHAMELEON_SHARING_PORTAL_UPDATE_URL: (str) the full URL for the endpoint in
#                                      the Chameleon sharing portal that starts
#                                      the update flow.
import os
import sys

import jupyterhub_chameleon

c = get_config()

jupyterhub_chameleon.install_extension(c)

debug = os.getenv('DEBUG', '').strip().lower() in ['1', 'true', 'yes']

##################
# Logging
##################

log_level = 'DEBUG' if debug else 'INFO'

c.Application.log_level = c.JupyterHub.log_level = log_level
c.ChameleonSpawner.debug = debug

###################
# Notebook args
###################

jupyterlab_args = {
    'ZenodoConfig.upload_redirect_url': os.getenv('CHAMELEON_SHARING_PORTAL_UPLOAD_URL', ''),
    'ZenodoConfig.update_redirect_url': os.getenv('CHAMELEON_SHARING_PORTAL_UPDATE_URL', ''),
    'ZenodoConfig.dev': debug,
}

c.ChameleonSpawner.args.extend([
    f"--{k}={v}" for k, v in jupyterlab_args.items()
])

##################
# Hub
##################

# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_ip = 'jupyterhub'
c.JupyterHub.hub_port = 8080
c.JupyterHub.bind_url = 'http://:8000'
c.JupyterHub.base_url = os.environ.get('JUPYTERHUB_BASE_URL', '/')

# Persist hub data on volume mounted inside container
data_dir = os.environ.get('DATA_VOLUME_CONTAINER', '/data')

c.JupyterHub.cookie_secret_file = os.path.join(data_dir,
    'jupyterhub_cookie_secret')

c.JupyterHub.db_url = 'mysql+mysqldb://{user}:{password}@{host}/{db}'.format(
    host=os.environ['MYSQL_HOST'],
    user=os.environ['MYSQL_USER'],
    password=os.environ['MYSQL_PASSWORD'],
    db=os.environ['MYSQL_DATABASE'],
)

# Whitelist admins.
c.Authenticator.admin_users = admin = set()
# Allow admins to manage single-server instances of users.
c.JupyterHub.admin_access = True
pwd = os.path.dirname(__file__)
with open(os.path.join(pwd, 'adminlist')) as f:
    for line in f:
        if not line:
            continue
        admin.add(line.strip())
