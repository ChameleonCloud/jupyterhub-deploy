FROM jupyterhub/jupyterhub-onbuild:1.0.0

RUN conda install -c bioconda mysqlclient \
    && conda clean -tipsy \
    && pip install --no-cache-dir \
      jupyterhub-keystoneauthenticator \
      dockerspawner~=0.11.0

COPY ./adminlist /srv/jupyterhub/adminlist
