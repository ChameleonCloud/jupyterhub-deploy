from neutronclient.v2_0 import client as neutronclient
from novaclient import client as novaclient
from chameleon import utils
from time import sleep

import logging
logger = logging.getLogger(__name__)

def _neutronclient(session):
    return neutronclient.Client(session=session)

def _novaclient(session):
    return novaclient.Client('2', session=session)

def create(session, lease=None, name=None, image='CC-CentOS7', flavor='baremetal',
           network_name='sharednet1'):
    if not lease:
        raise Exception('No lease defined. Please provide a target lease.')

    if name is None:
        name = utils._rand_name('server')

    reservation = lease['reservations'][0]['id']

    neutron = _neutronclient(session)
    nova = _novaclient(session)

    networks = neutron.list_networks(name='sharednet1')
    network_id = networks['networks'][0]['id']
    glance_image = nova.glance.find_image(image)
    nova_flavor = nova.flavors.get(flavor)
    server = nova.servers.create(name, glance_image, nova_flavor,
                                 nics=[{'net-id': network_id}],
                                 scheduler_hints={'reservation': reservation})
    return server

def _server_is_active(session, server):
    return _novaclient(session).servers.get(server.id).state == 'ACTIVE'

def connect(session, server):
    # Ensure server is active
    while not _server_is_active(session, server):
        logger.info('Waiting for server to become active...')
        sleep(10)

    # Create ephemeral keypair
    _novaclient(session).keypairs.create('demo')

    # Associate floating IP
    floating_ips = _neutronclient(session).list_floatingips()
    floating_ip = floating_ips['floatingips'][0]['id']
    logger.info(floating_ip)
    logger.info('The rest is not implemented yet.')

    # Attempt to create SSH session
    # Return SSH paramiko wrapper
    return None
