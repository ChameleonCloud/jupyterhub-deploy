ARG base_image=jupyterhub/jupyterhub:1.2
FROM $base_image as base

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
        libmariadbclient-dev \
    && rm -rf /var/lib/apt/lists/*

FROM base as builder

WORKDIR /src/jupyterhub
RUN python3 -m pip install --upgrade wheel

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
         build-essential \
         git-core \
         python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip wheel --wheel-dir wheelhouse \
      mysqlclient \
      jupyterhub-keystoneauthenticator~=0.2.6 \
      git+https://github.com/chameleoncloud/dockerspawner.git@volume-drivers#egg=dockerspawner

FROM base

# Install the wheels we built in the first stage
#
# NOTE(jason): /tmp/wheelhouse already exists due to the base image. COPY
# will not replace the existing contents and can therefore cause problems
# where multiple copies of wheels are stored in the wheel directory, which
# causes errors on install. Use a different directory (wheelhouse-custom here).
COPY --from=builder /src/jupyterhub/wheelhouse /tmp/wheelhouse-custom
RUN python3 -m pip install --no-cache /tmp/wheelhouse-custom/*

COPY entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py

RUN python3 -m pip install jupyterhub-chameleon~=0.1.0

COPY adminlist /srv/jupyterhub/adminlist

CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
