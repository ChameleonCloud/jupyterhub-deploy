# Original copyright (c) Jupyter Development Team.
# Modified copyright (c) University of Chicago.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os
import sys
import hashlib

from urllib.parse import parse_qsl, unquote, urlencode
from dockerspawner import DockerSpawner
from jupyterhub.handlers import BaseHandler
from jupyterhub.utils import url_path_join
from tornado import web
from tornado.httputil import url_concat

c = get_config()

server_idle_timeout = 60 * 60 * 24
server_max_age = 60 * 60 * 24 * 7
kernel_idle_timeout = 60 * 60 * 2

debug = os.getenv('DEBUG', '').strip().lower() in ['1', 'true', 'yes']

##################
# Logging
##################

log_level = 'DEBUG' if debug else 'INFO'

c.Application.log_level = log_level
c.JupyterHub.log_level = log_level
c.Spawner.debug = debug
c.DockerSpawner.debug = debug

##################
# Base spawner
##################

def docker_volume_opts():
    opt_str = os.getenv('DOCKER_VOLUME_DRIVER_OPTS', '')
    tuples = [s.split('=') for s in opt_str.split(',') if s]
    return {t[0]: t[1] for t in tuples if len(t) == 2}

# This is where we can do other specific bootstrapping for the user environment
def pre_spawn_hook(spawner):
    query = dict(parse_qsl(spawner.handler.request.query))

    username = spawner.user.name
    # Run as authenticated user
    spawner.environment['NB_USER'] = username
    spawner.environment['OS_INTERFACE'] = 'public'
    spawner.environment['OS_KEYPAIR_PRIVATE_KEY'] = '/home/{}/.ssh/id_rsa'.format(username)
    spawner.environment['OS_KEYPAIR_PUBLIC_KEY'] = '/home/{}/.ssh/id_rsa.pub'.format(username)
    spawner.environment['OS_PROJECT_DOMAIN_NAME'] = 'default'
    spawner.environment['OS_REGION_NAME'] = 'CHI@UC'

    if 'source' in query:
        spawner.environment['IMPORT_SRC'] = query.get('source')
        spawner.environment['SRC_PATH'] = query.get('src_path')

        # Change volume/server names to include assigned server name
        # (Allows multiple named servers/experiments per user)
        spawner.name_template = '{prefix}-{username}-exp-{servername}'
        spawner.volumes = {
            '{prefix}-{username}-exp-{servername}': {
                'target': '/work',
                'driver': os.getenv('DOCKER_VOLUME_DRIVER', 'local'),
                'driver_opts': docker_volume_opts(),
            }
        }

origin = '*'
c.Spawner.args = ['--NotebookApp.allow_origin={0}'.format(origin)]
c.Spawner.pre_spawn_hook = pre_spawn_hook
c.Spawner.mem_limit = '2G'
c.Spawner.http_timeout = 600


##################
# Docker spawner
##################

# Set spawner names to work for multiple servers
c.DockerSpawner.name_template = '{prefix}-{username}'

# Spawn single-user servers as Docker containers wrapped by the option form
c.JupyterHub.spawner_class = DockerSpawner

# Spawn containers from this image
c.DockerSpawner.image = os.environ['DOCKER_NOTEBOOK_IMAGE']

# Connect containers to this Docker network
network_name = os.environ['DOCKER_NETWORK_NAME']
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name

# Configure docker host vars
# This is where container resource limits are set. Note the
# cpu_period and cpu_quota settings: the quota divided by the
# period is effectively how many cores a container will be allowed
# to have in a CPU-bound scheduling situation, e.g. 100/100 = 1 core.
c.DockerSpawner.extra_host_config = {
    'network_mode': network_name,
    'mem_limit': '1G',
    'cpu_period': 100000, # nanosecs
    'cpu_quota': 100000, # nanosecs
}
notebook_dir = os.environ['DOCKER_NOTEBOOK_DIR']

# This directory will be symlinked to the `notebook_dir` at runtime.
c.DockerSpawner.notebook_dir = '~/work'

# Mount the real user's Docker volume on the host to the
# notebook directory in the container for that server
c.DockerSpawner.volumes = { '{prefix}-{username}': '/work' }

# Remove containers once they are stopped
c.DockerSpawner.remove_containers = True
c.DockerSpawner.extra_create_kwargs.update({
    # Need to launch the container as root in order to grant sudo access
    'user': 'root'
})

c.DockerSpawner.environment = {
    'CHOWN_EXTRA': notebook_dir,
    'CHOWN_EXTRA_OPTS': '-R',
    # Allow users to have sudo access within their container
    'GRANT_SUDO': 'yes',
    # Enable JupyterLab application
    'JUPYTER_ENABLE_LAB': 'yes',
}

###################
# Notebook args
###################

jupyterlab_args = {
    'NotebookApp.shutdown_no_activity_timeout': server_idle_timeout,
    'MappingKernelManager.cull_idle_timeout': kernel_idle_timeout,
    'MappingKernelManager.cull_interval': kernel_idle_timeout // 8,
    'ZenodoConfig.access_token': os.getenv('ZENODO_DEFAULT_ACCESS_TOKEN'),
    'ZenodoConfig.upload_redirect_url': os.getenv('CHAMELEON_SHARING_PORTAL_UPLOAD_URL', ''),
    'ZenodoConfig.dev': debug,
}

c.DockerSpawner.cmd = (
    ['start-notebook.sh'] + [f"--{k}={v}" for k, v in jupyterlab_args.items()]
)

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

# Allow named servers
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


##################
# Handlers
##################

from tornado import web

class UserRedirectExperimentHandler(BaseHandler):
    """Redirect spawn requests to user servers.
    /import?{query vars} will spawn a new experiment server
    Server will be initialized with a git repo/zenodo zip file as specified
    If the user is not logged in, send to login URL, redirecting back here.
    Added by: Maxine
    """

    @web.authenticated
    def get(self):
        base_spawn_url = url_path_join(
            self.hub.base_url, 'spawn', self.current_user.name)

        if self.request.query:
            query = dict(parse_qsl(self.request.query))
            source = query.get('source')
            path = query.get('src_path')

            if not (source and path):
                raise web.HTTPError(400, (
                    'Missing required arguments: source, src_path'))

            sha = hashlib.sha256()
            sha.update(source.encode('utf-8'))
            sha.update(path.encode('utf-8'))
            server_name = sha.hexdigest()[:7]

            # Auto-open file when we land in server
            if 'file_path' in query:
                file_path = query.pop('file_path')
                query['next'] = url_path_join(self.hub.base_url, 'user', self.current_user.name, server_name, 'lab/tree', file_path)

            spawn_url = url_path_join(base_spawn_url, server_name)
            spawn_url += '?' + urlencode(query)
        else:
            spawn_url = base_spawn_url

        self.redirect(spawn_url)

c.JupyterHub.extra_handlers = [
    (r'/import', UserRedirectExperimentHandler),
]
