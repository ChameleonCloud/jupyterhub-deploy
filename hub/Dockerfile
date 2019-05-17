FROM jupyterhub/jupyterhub:1.0.0

RUN conda install -c bioconda mysqlclient \
    && conda clean -tipsy \
    && pip install --no-cache-dir \
      jupyterhub-keystoneauthenticator~=0.1.3 \
      dockerspawner~=0.11.0

COPY cull_idle_servers.py /srv/jupyterhub/cull_idle_servers.py
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
COPY adminlist /srv/jupyterhub/adminlist

CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
