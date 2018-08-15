
# coding: utf-8

# In[7]:


from chameleon import session
from novaclient import client

region = 'CHI@TACC'
sess = session.factory('Chameleon', region_name=region)
nova = client.Client('2', session=sess)
instances = nova.servers.list()

print('Listing instances in region={}'.format(region))
[i.name for i in instances]


# ## Okay
#
# Now we are going to do something cool

# In[8]:


# Do we still have the client?
[i.name for i in nova.servers.list()]


# In[45]:


# Let's create a lease
from blazarclient import client
from datetime import datetime, timedelta

node_type = 'compute_haswell'
start = datetime.utcnow()
end = start + timedelta(hours=1)

def blazar_datetime(dt):
    return dt.strftime('%Y-%m-%d %H:%M')

# This 'service_type' thing is kind of annoying, shouldn't be necessary. Ignore.
blazar = client.Client('1', session=sess, service_type='reservation')
lease = blazar.lease.create('jupyter-demo', blazar_datetime(start), blazar_datetime(end),
                            [{
                                'resource_type': 'physical:host',
                                'resource_properties': '["=", "$node_type", "{}"]'.format(node_type),
                                'hypervisor_properties': None, # For some reason you need to explicitly send this
                                'min': 1,
                                'max': 1,
                            }],
                            [])

print('Started lease {}'.format(lease['name']))


# In[46]:


# Now let's launch an instance

# Have to do some extra work...
from neutronclient.v2_0 import client
neutron = client.Client(session=sess)
networks = neutron.list_networks(name='sharednet1')
sharednet = networks['networks'][0]['id']

# Remember our nova client from before?
centos_image = nova.glance.find_image('CC-CentOS7')
baremetal_flavor = nova.flavors.get('baremetal')
server = nova.servers.create('jupyter-demo', centos_image, baremetal_flavor,
                    nics=[{'net-id': sharednet}],
                    key_name='jason',
                    scheduler_hints={'reservation': lease['reservations'][0]['id']})

print('Started spawning server {}'.format(server.name))
