# jupyterhub-deploy

This repo contains the definitions of Chameleon JupyterHub Docker images. These images are used when provisioning a JupyterHub server using [Ansible](https://github.com/ChameleonCloud/ansible-playbooks/tree/master/roles/jupyterhub).

There are two images defined, each in its own directory:

  - **[hub](./hub)**: the [JupyterHub](https://jupyter.org/hub) image. JupyterHub is the multi-user environment that supports authentication of users and the orchestration of single-user Jupyter Notebook servers for each user.
  - **[singleuser](./singleuser)**: the single-user Jupyter Notebook image. A copy of this is run for each user logged in to the JupyterHub server.

## Releasing new versions

To build and release a new version of either the JupyterHub server or the single-user Notebook image, use the `*-build` and `*-publish` targets.

> **Note**: this will always override the version currently existing on the repository - we currently do not version these images, other than including the JupyterHub release version as a tag.

```
# Publish the JupyterHub image to the Docker registry
make hub-build
make hub-publish

# Publish the single-user Notebook image to the Docker registry
make singleuser-build
make singleuser-publish
```

## Development

### System requirements

  - [Docker](https://docs.docker.com/install/)
  - [Docker Compose](https://docs.docker.com/compose/install/)

### Quick start

First build both the hub and single-user images.

```
make hub-build singleuser-build
```

Then, start up the JupyterHub stack. This will create a MySQL database and start the JupyterHub container.

```
make hub-start
```

At this point, you should have a [JupyterHub server](http://localhost:8000) running on your localhost port 8000. You can log in to the JupyterHub server using your Chameleon credentials.

### Running just the single-user Notebook

If you are testing some changes to just the single-user Notebook, it can be easier to just run the Notebook server by itself without the hub. To do this, there is a special start target that starts the Notebook, mounting the current working directory.

```
make singleuser-start
```

When the Notebook starts, a `token` value will be outputted as part of a url. Navigate to the local [Notebook server](http://localhost:8888) and input this token to log in.

To change the Notebook working directory, provide a `JUPYTERHUB_SINGLEUSER_WORKDIR` environment variable. This can be useful if you are developing a JupyterLab extension, for example. This directory will be mounted at `/work` inside the Notebook container and will also be the "home" directory in the JupyterLab interface.

```
# Mounts the parent directory instead of current working directory
JUPYTERHUB_SINGLEUSER_WORKDIR=$(realpath ..) make singleuser-start
```
