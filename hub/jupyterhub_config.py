# Copyright (c) University of Chicago.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
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
