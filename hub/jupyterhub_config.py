# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os
import sys
import urllib
import time
from urllib.parse import parse_qsl
from dockerspawner import DockerSpawner
from jupyterhub.handlers import BaseHandler
from jupyterhub.utils import url_path_join
from tornado import web
from tornado.httputil import url_concat

# Spawner wrapper to create server options
class DemoFormSpawner(DockerSpawner):
    def _options_form_default(self):
        default_src = "zenodo"
        default_imp = "yes"
        default_src_path = "google.com"
        return """
        <p> Loading your custom options... please wait... </p>
        <div id ="hidden_form" style="display:none">
        <label for="imported">Are you importing an experiment?</label>
        <select id="imported" name="imported" size="1" onchange="console.log(window.location.href)">
        <option value="no"> No </option>
        <option value="yes"> Yes </option>
        <option value="hello"> hello </option>
        </select>
        <label for="source">Select your desired source</label>
        <select id="source" name="source" size="1">
        <option value="git"> Git </option>
        <option value="zenodo"> Zenodo </option>
        </select>
        <p>
        <label for="src_path">Enter the source path</label>
        <input id = "src_path" name="src_path" placeholder="eg:record/2647697/files/LaGuer/Jupyter-Notebook-Practice-Physical-Constants-Ratios-v0.0.102.zip"></input>
        </p>
        </div>
        <script>
        var query = window.location.search.substring(1);
        console.log(query)
        var vars = query.split("&");
        if (vars.length != 3)
            vars = ["imported=no","source=git", "src_path=none"]
        console.log(vars);
        var pair = vars[0].split("=");
        if (pair[0] == "imported")
            document.getElementById("imported").value = pair[1]
        var pair = vars[1].split("=");
        if (pair[0] == "source")
            document.getElementById("source").value = pair[1]
        var pair = vars[2].split("=");
        if (pair[0] == "src_path")
            document.getElementById("src_path").value = pair[1]

        document.getElementById("spawn_form").submit()
        </script>
        """.format(imported=default_imp,source=default_src,src_path=default_src_path)

    def options_from_form(self, formdata):
        options = {}
        options['imported'] = formdata['imported']
        options['source'] = formdata['source']
        options['src_path'] = formdata['src_path']
        
        return options

c = get_config()

server_idle_timeout = 60 * 60 * 24
server_max_age = 60 * 60 * 24 * 7
kernel_idle_timeout = 60 * 60 * 2

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
    imported = ''.join(spawner.user_options['imported'])
    source = ''.join(spawner.user_options['source'])
    src_path = urllib.parse.unquote(''.join(spawner.user_options['src_path']))
    # Prints data 
    cmd = "echo 'looking for imported, source, src_path in pre-spawn hook'"
    os.system(cmd)
    cmd = "echo '"+imported+"'"
    os.system(cmd)
    cmd = "echo '"+source+"'"
    os.system(cmd)
    cmd = "echo '"+src_path+"'"
    os.system(cmd)
    cmd = "echo '"+str(spawner)+"'"
    os.system(cmd)

    username = spawner.user.name
    # Run as authenticated user
    spawner.environment['NB_USER'] = username
    spawner.environment['OS_INTERFACE'] = 'public'
    spawner.environment['OS_KEYPAIR_PRIVATE_KEY'] = '/home/{}/.ssh/id_rsa'.format(username)
    spawner.environment['OS_KEYPAIR_PUBLIC_KEY'] = '/home/{}/.ssh/id_rsa.pub'.format(username)
    spawner.environment['OS_PROJECT_DOMAIN_NAME'] = 'default'
    spawner.environment['OS_REGION_NAME'] = 'CHI@UC'
    # Indicates if cloning/downloading needs to occur
    spawner.environment['IS_IMPORTED'] = imported
    # Set source
    spawner.environment['IMPORT_SRC'] = source
    # Set link
    spawner.environment['SRC_PATH'] = src_path

origin = '*'
c.Spawner.args = ['--NotebookApp.allow_origin={0}'.format(origin)]
c.Spawner.pre_spawn_hook = pre_spawn_hook
c.Spawner.mem_limit = '2G'
c.Spawner.http_timeout = 120


##################
# Docker spawner
##################

# Set spawner names to work for multiple servers
c.DockerSpawner.name_template = '{prefix}-{username}-{servername}'

# Spawn single-user servers as Docker containers wrapped by the option form
c.JupyterHub.spawner_class = DemoFormSpawner

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
# notebook directory in the container for that server
c.DockerSpawner.volumes = { 'jupyterhub-user-{username}-{servername}': notebook_dir }

   
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

class UserRedirectExperimentHandler(BaseHandler):
    """Redirect spawn requests to user servers.
    /import/ will spawn a new experiment server
    If the user is not logged in, send to login URL, redirecting back here.
    Added by: Maxine
    """

    @web.authenticated
    def get(self, path):
        cmd = "echo 'hello"+path+"'"
        os.system(cmd)
        user = self.current_user
        user_url = url_path_join(user.url, path)
        if self.request.query:
            user_url = url_concat(user_url, parse_qsl(self.request.query))

        url = url_concat(
            url_path_join(self.hub.base_url, "spawn", user.name), {"next": user_url}
        )
        url = url.replace("exp_name","experiment"+str(int(time.time())),1)
        url = url.replace("user","hub/spawn",1)

        self.redirect(url)

c.JupyterHub.extra_handlers = [
    (r'/import/(.*)?', UserRedirectExperimentHandler),
]


