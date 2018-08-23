# jupyterhub-deploy

A proof of concept for how to deploy JupyterHub with Docker containers.

## Requirements

  = Docker 18.x

## Setup

First, build the notebook image. This is the base image that is used to create the single-user Jupyter notebook server that you actually interact with.

```
make notebook_image
```

Then, start up the JupyterHub stack. This will create a MySQL database and also a JupyterHub container (along with a SSL proxy).

```
make build
```

After the stack is built, it can be started:

```
make start
```

At this point, you should have a JupyterHub server running on your localhost port 443. You will have to confirm the security exception, as the certificate is self-signed.
You can log in to the JupyterHub server using your Chameleon credentials.

