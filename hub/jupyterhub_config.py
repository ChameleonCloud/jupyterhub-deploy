# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os
import sys

#MAXINE: add time
from datetime import datetime

c = get_config()

server_idle_timeout = 60 * 60 * 24
server_max_age = 60 * 60 * 24 * 7
kernel_idle_timeout = 60 * 60 * 2

##################
# Logging
##################

#MAXINE: changed log level from 'INFO' to 'DEBUG'
c.Application.log_level = 'DEBUG'
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
    spawner.environment['OS_INTERFACE'] = 'public'
    spawner.environment['OS_KEYPAIR_PRIVATE_KEY'] = '/home/{}/.ssh/id_rsa'.format(username)
    spawner.environment['OS_KEYPAIR_PUBLIC_KEY'] = '/home/{}/.ssh/id_rsa.pub'.format(username)
    spawner.environment['OS_PROJECT_DOMAIN_NAME'] = 'default'
    spawner.environment['OS_REGION_NAME'] = 'CHI@UC'

origin = '*'
c.Spawner.args = ['--NotebookApp.allow_origin={0}'.format(origin)]
c.Spawner.pre_spawn_hook = pre_spawn_hook
c.Spawner.mem_limit = '2G'
c.Spawner.http_timeout = 120

##################
# Docker spawner
##################

# MAXINE: Adjust server names to avoid container conflicts
c.DockerSpawner.name_template = '{prefix}-{username}-{servername}'

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

#MAXINE: added if statement and imported variable
#imported = (os.environ.get('IS_IMPORTED') == 'yes')
imported = False

#MAXINE: added to see what on earth is happening
with open("importlog.txt", "a") as f:
    f.write("["+str(datetime.now())+"]: "+str(imported)+"\n")
# current = os.environ.get('MK_TEST')
# os.environ['MK_TEST'] = str(current) + "1"

# this was originally in there
# Mount the real user's Docker volume on the host to the
# notebook directory in the container
# c.DockerSpawner.volumes = { 'jupyterhub-user-{username}': notebook_dir }
#MAXINE: commented out above line, added below line
c.DockerSpawner.volumes = { 'jupyterhub-user-{username}-{servername}': notebook_dir }

if not imported:
    # MAXINE: moved this from "1"
    c.DockerSpawner.environment = {
        'CHOWN_EXTRA': notebook_dir,
        'CHOWN_EXTRA_OPTS': '-R',
        # Allow users to have sudo access within their container
        'GRANT_SUDO': 'yes',
        # Enable JupyterLab application
        'JUPYTER_ENABLE_LAB': 'yes',
    }
else:
    # MAXINE: modified this, which I moved from "1"
    c.DockerSpawner.environment = {
        'CHOWN_EXTRA': notebook_dir,
        'CHOWN_EXTRA_OPTS': '-R',
        # Allow users to have sudo access within their container
        'GRANT_SUDO': 'yes',
        # Enable JupyterLab application
        'JUPYTER_ENABLE_LAB': 'yes',
        # Note that git clone should happen
        'IS_IMPORTED' : 'yes',
    }
   
# Remove containers once they are stopped
c.DockerSpawner.remove_containers = True
c.DockerSpawner.extra_create_kwargs.update({
    # Need to launch the container as root in order to grant sudo access
    'user': 'root'
})
# 1

c.DockerSpawner.cmd = [
    'start-notebook.sh',
    '--NotebookApp.shutdown_no_activity_timeout={}'.format(server_idle_timeout),
    '--MappingKernelManager.cull_idle_timeout={}'.format(kernel_idle_timeout),
    '--MappingKernelManager.cull_interval={}'.format(kernel_idle_timeout // 8)
]

##################
# Authentication
##################

# Authenticate users with Keystone
c.JupyterHub.authenticator_class = 'keystoneauthenticator.KeystoneAuthenticator'
c.KeystoneAuthenticator.auth_url = os.environ['OS_AUTH_URL']
# KeystoneAuthenticator uses auth_state to store Keystone token information
c.Authenticator.enable_auth_state = True
# Check state of authentication token before allowing a new server launch;
# The Keystone authenticator will fail if the user's unscoped token has expired,
# forcing them to log in, which is the right thing.
c.Authenticator.refresh_pre_spawn = True
# Automatically check the auth state this often. Not super useful for us, as
# there's nothing we can really do about this.
c.Authenticator.auth_refresh_age = 60 * 60
# Keystone tokens only last 7 days; limit sessions to this amount of time too.
c.JupyterHub.cookie_max_age_days = 7

##################
# Hub
##################

# MAXINE: Allow named servers 
c.JupyterHub.allow_named_servers = True

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

# Enable restarting of Hub without affecting singleuser servers
c.JupyterHub.cleanup_servers = False
c.JupyterHub.cleanup_proxy = False

# Automatically cull idle servers
c.JupyterHub.services = [
    {
        'name': 'cull-idle',
        'admin': True,
        'command': [
            sys.executable,
            'cull_idle_servers.py',
            '--timeout={}'.format(server_idle_timeout),
            '--max_age={}'.format(server_max_age),
            '--cull_every={}'.format(60 * 15),
        ],
    },
]

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
