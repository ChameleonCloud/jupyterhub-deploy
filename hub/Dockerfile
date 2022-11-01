ARG base_image=jupyterhub/jupyterhub:1.4
FROM $base_image as base

RUN apt-get update \
    && apt-get remove -yq python3-pycurl \
    && apt-get install -yq --no-install-recommends \
      libmariadbclient-dev \
      libssl-dev \
      libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

ENV PYCURL_SSL_LIBRARY=openssl

FROM base as builder

WORKDIR /src/jupyterhub
RUN python3 -m pip install --upgrade setuptools wheel

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
    build-essential \
    git-core \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip wheel --wheel-dir wheelhouse \
    mysqlclient \
    netifaces \
    pycurl \
    git+https://github.com/chameleoncloud/dockerspawner.git@volume-drivers#egg=dockerspawner

FROM base as release

# Install the wheels we built in the first stage
#
# NOTE(jason): /tmp/wheelhouse already exists due to the base image. COPY
# will not replace the existing contents and can therefore cause problems
# where multiple copies of wheels are stored in the wheel directory, which
# causes errors on install. Use a different directory (wheelhouse-custom here).
COPY --from=builder /src/jupyterhub/wheelhouse /tmp/wheelhouse-custom
RUN python3 -m pip install --no-cache /tmp/wheelhouse-custom/*

WORKDIR /srv/jupyterhub
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py

COPY requirements.txt /srv/jupyterhub/requirements.txt
RUN python3 -m pip install -r /srv/jupyterhub/requirements.txt

COPY adminlist /srv/jupyterhub/adminlist

CMD ["jupyterhub"]

FROM release as dev

# File watcher for running tests on watch mode
RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
    build-essential git-core \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/eradman/entr /opt/entr \
    && cd /opt/entr \
    && git checkout tags/5.2 \
    && ./configure \
    && make test \
    && make install

COPY start-jupyterhub-dev.sh /usr/local/bin/
