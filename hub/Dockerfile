FROM jupyterhub/jupyterhub-onbuild:0.9.4

# Install mysql client and dockerspawner
RUN /opt/conda/bin/conda install -c bioconda mysqlclient=1.3 && \
    /opt/conda/bin/conda clean -tipsy && \
    /opt/conda/bin/pip install --no-cache-dir \
        dockerspawner==0.9

COPY ./keystoneauthenticator /opt/keystoneauthenticator
RUN cd /opt/keystoneauthenticator && python setup.py install

COPY ./adminlist /srv/jupyterhub/adminlist
