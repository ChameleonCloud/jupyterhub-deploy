# jupyterhub-deploy

This repo contains the definitions of Chameleon JupyterHub Docker images. These images are used when provisioning a JupyterHub server using [Ansible](https://github.com/ChameleonCloud/ansible-playbooks/tree/master/roles/jupyterhub).

There are two images defined, each in its own directory:

  - **[hub](./hub)**: the [JupyterHub](https://jupyter.org/hub) image. JupyterHub is the multi-user environment that supports authentication of users and the orchestration of single-user Jupyter Notebook servers for each user.
  - **[singleuser](./singleuser)**: the single-user Jupyter Notebook image. A copy of this is run for each user logged in to the JupyterHub server.

## Releasing new versions

To build and release a new version of either the JupyterHub server or the single-user Notebook image, use the `*-build` and `*-publish` targets. New releases are always tagged with the Git SHA of the latest commit that touched the directory containing the build definitions.

**Note**: when releasing new versions, particularly when dependences are updated, it is particularly important to ensure compatibility between the version of JupyterHub built and the version of JupyterLab used in the single-user image. Ensure the base image for the singleuser image (we use the [minimal-notebook](https://github.com/jupyter/docker-stacks/tree/master/minimal-notebook) Docker stack provided by Jupyter) has a matching JupyterHub version.

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

To change the Notebook working directory, provide a `JUPYTERHUB_SINGLEUSER_WORKDIR` environment variable. This can be useful if you are testing a local Notebook or want to reference files on your host system in your Notebook directory. This directory will be mounted at `/work` inside the Notebook container and will also be the "home" directory in the JupyterLab interface.

```
# Mounts the parent directory instead of current working directory
JUPYTERHUB_SINGLEUSER_WORKDIR=$(realpath ..) make singleuser-start
```

#### Mounting a local extension

If you are doing local JupyterLab extension development, you likely want an easy way to test the extension. You can do that by specifying the `JUPYTERHUB_SINGLEUSER_EXTDIR` environment variable. This will be mounted at /ext inside the container. Additionally, the server will automatically detect that this mount exists and build/install your server and client extensions automatically.

```
# Mounts a special directory containing a local extension
JUPYTERHUB_SINGLEUSER_EXTDIR=$(realpath ..) make singleuser-shell
```

**Note**: currently watch mode is not very well supported, though it should be possible especially when running via the 'shell' targets.
