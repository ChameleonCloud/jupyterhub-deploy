# jupyterhub-deploy

This repo contains the Chameleon configurations of a JupyterHub installation. The JupyterHub instance itself is provisioned with [Ansible](https://github.com/ChameleonCloud/ansible-playbooks/tree/master/roles/jupyterhub).

## Development

### System requirements

  - [Docker 18.x](https://docs.docker.com/install/)

### Setup

First, build the notebook image. This is the base image that is used to create the single-user Jupyter notebook server that you actually interact with.

```
make singleuser
```

Then, start up the JupyterHub stack. This will create a MySQL database and also a JupyterHub container.

```
make build
```

After the stack is built, it can be started:

```
make start
```

At this point, you should have a [JupyterHub server](http://localhost:8000) running on your localhost port 8000. You can log in to the JupyterHub server using your Chameleon credentials.

### Publishing new versions

To publish a new version of either the JupyterHub server or the single-user Notebook image, run one of the `publish` targets.

```
# Publish the JupyterHub image to the Docker registry
make publish

# Publish the single-user Notebook image to the Docker registry
make singleuser-publish
```

**Note**: this will always override the version currently existing on the repository - we currently do not version these images, other than including the JupyterHub release version as a tag.
