# jupyterhub-deploy

This repo contains the definitions of Chameleon JupyterHub Docker images. These images are used when provisioning a JupyterHub server using [Ansible](https://github.com/ChameleonCloud/ansible-playbooks/tree/master/roles/jupyterhub).

There are two images defined, each in its own directory:

  - **[hub](./hub)**: the [JupyterHub](https://jupyter.org/hub) image. JupyterHub is the multi-user environment that supports authentication of users and the orchestration of single-user Jupyter Notebook servers for each user.
  - **[singleuser](./singleuser)**: the single-user Jupyter Notebook image. A copy of this is run for each user logged in to the JupyterHub server.

## Releasing new versions

To build and release a new version of either the JupyterHub server or the single-user Notebook image, use the `*-build` and `*-publish` targets. New releases are always tagged with the Git SHA of the latest commit that touched the directory containing the build definitions.

```
# Publish the JupyterHub image to the Docker registry
make hub-build
make hub-publish

# Publish the single-user Notebook image to the Docker registry
make singleuser-build
make singleuser-publish
```

**Note**: if you are building these images on a local (development) machine running Mac OS X, you will probably have to increase the amount of RAM available to Docker or risk your builds being mysteriously killed due to hitting memory limits. This can be configured in the Preferences for Docker for Mac; a value of 4G should be high enough.

### Upgrading the Hub image

When upgrading the Hub image, a few things should be done:

1. Check the [JupyterHub changelog](https://jupyterhub.readthedocs.io/en/stable/changelog.html) to see if there are any breaking changes or important things to note.
2. Check if there are updates to the [`cull_idle_servers.py`](https://github.com/jupyterhub/jupyterhub/blob/master/examples/cull-idle/cull_idle_servers.py) service, which is copied directly from the JupyterHub repo.

**Note**: when releasing new versions, particularly when dependences are updated, it is particularly important to ensure compatibility between the version of JupyterHub built and the version of JupyterLab used in the single-user image. Ensure the base image for the singleuser image (we use the [minimal-notebook](https://github.com/jupyter/docker-stacks/tree/master/minimal-notebook) Docker stack provided by Jupyter) has a matching JupyterHub version.

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
./run.sh
```

At this point, you should have a [JupyterHub server](http://localhost:8000) running on your localhost port 8000. You can log in to the JupyterHub server using your Chameleon credentials.

### Running just the single-user Notebook

If you are testing some changes to just the single-user Notebook, it can be easier to just run the Notebook server by itself without the hub. To do this, there is a special start target that starts the Notebook, mounting the current working directory.

```
./run.sh --single
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

> **Note**: If you are testing a local extension which has a released copy already installed to the singleuser image, you should uninstall the installed version first:
>
> `jupyter serverextension disable <module> && pip uninstall <module>`
>
> Otherwise, you may run in to odd behavior where the updated module is not properly linked in to the Jupyter server.

### Testing Zenodo publish flow

Currently, the sharing portal publish flow via Zenodo requires an [access token](https://developers.zenodo.org/#creating-a-personal-access-token), which is defined via an env variable `ZENODO_DEFAULT_ACCESS_TOKEN`. To set this for a local build, add it to the `./secrets/jupyterhub.env` file; those env variables are automatically sourced into the JupyterHub environment and passed to the single-user environments as Notebook configuration parameters.

If you want to test with just the single-user environment, use the `singleuser-shell` target to get an interactive shell into the Notebook environment and, instead of setting the value with an environment variable, pass it directly as a flag to the Notebook start script:

```bash
start-notebook.sh --ZenodoConfig.access_token='<token>'
```
