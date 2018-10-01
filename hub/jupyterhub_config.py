# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os

c = get_config()

##################
# Logging
##################

c.Application.log_level = 'INFO'
c.JupyterHub.log_level = 'INFO'
c.Spawner.debug = False
c.DockerSpawner.debug = False

##################
# Base spawner
##################

from subprocess import check_call
# This is where we can do other specific bootstrapping for the user environment
def pre_spawn_hook(spawner):
    username = spawner.user.name
    # Run as authenticated user
    spawner.environment['NB_USER'] = username
    spawner.environment['OS_IDENTITY_API_VERSION'] = '3'
    spawner.environment['OS_INTERFACE'] = 'public'
    spawner.environment['OS_KEYPAIR_PRIVATE_KEY'] = '/home/{}/.ssh/id_rsa'.format(username)
    spawner.environment['OS_KEYPAIR_PUBLIC_KEY'] = '/home/{}/.ssh/id_rsa.pub'.format(username)
    spawner.environment['OS_PROJECT_DOMAIN_NAME'] = 'default'
    spawner.environment['OS_USER_DOMAIN_NAME'] = 'default'

origin = '*'
c.Spawner.args = ['--NotebookApp.allow_origin={0}'.format(origin)]
c.Spawner.pre_spawn_hook = pre_spawn_hook
c.Spawner.mem_limit = '2G'

##################
# Docker spawner
##################

# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'

# Spawn containers from this image
c.DockerSpawner.image = os.environ['DOCKER_NOTEBOOK_IMAGE']
# Connect containers to this Docker network
network_name = os.environ['DOCKER_NETWORK_NAME']
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name
# Pass the network name as argument to spawned containers
c.DockerSpawner.extra_host_config = { 'network_mode': network_name }
notebook_dir = os.environ['DOCKER_NOTEBOOK_DIR']
# This directory will be symlinked to the `notebook_dir` at runtime.
c.DockerSpawner.notebook_dir = '~/work'
# Mount the real user's Docker volume on the host to the
# notebook directory in the container
c.DockerSpawner.volumes = { 'jupyterhub-user-{username}': notebook_dir }
# Remove containers once they are stopped
c.DockerSpawner.remove_containers = True
# Need to launch the container as root in order to grant sudo access
c.DockerSpawner.extra_create_kwargs.update({ 'user': 'root' })
c.DockerSpawner.environment = {
    'CHOWN_EXTRA': notebook_dir,
    'CHOWN_EXTRA_OPTS': '-R',
    # Allow users to have sudo access within their container
    'GRANT_SUDO': 'yes',
    # Enable JupyterLab application
    'JUPYTER_ENABLE_LAB': 'yes',
}

##################
# Authentication
##################

# Authenticate users with Keystone
c.JupyterHub.authenticator_class = 'keystoneauthenticator.KeystoneAuthenticator'
c.KeystoneAuthenticator.auth_url = os.environ['OS_AUTH_URL']
# KeystoneAuthenticator uses auth_state to store Keystone token information
c.Authenticator.enable_auth_state = True

##################
# Hub
##################

# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_ip = 'jupyterhub'
c.JupyterHub.hub_port = 8080
c.JupyterHub.bind_url = 'http://:8000'

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
        admin.add(line)
