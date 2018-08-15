from keystoneauth1 import adapter, session
from keystoneauth1.identity import v3
from os import getenv

def factory(project_name, region_name=None):
    auth_url = getenv('OS_URL')
    token = getenv('OS_TOKEN')

    # Exchange unscoped token for project-scoped token
    auth = v3.Token(auth_url=auth_url, token=token,
                    project_name=project_name, project_domain_name='default')
    sess = session.Session(auth=auth)

    # Scope further to region if requested
    if region_name:
        sess = adapter.Adapter(session=sess, region_name=region_name)

    return sess
