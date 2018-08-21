from blazarclient import client
from datetime import datetime, timedelta
from chameleon import utils

def create(session, name=None, node_type='compute_haswell',
           start=datetime.utcnow(), end=None, min=1, max=1):
    def _blazar_datetime(dt):
        return dt.strftime('%Y-%m-%d %H:%M')

    if name is None:
        name = utils._rand_name('lease')

    if end is None:
        end = start + timedelta(hours=1)

    reservations = [{
        'resource_type': 'physical:host',
        'resource_properties': '["=", "$node_type", "{}"]'.format(node_type),
        'hypervisor_properties': None, # For some reason you need to explicitly send this
        'min': min,
        'max': max,
    }]

    # This 'service_type' thing is kind of annoying, shouldn't be necessary. Ignore.
    blazar = client.Client('1', session=session, service_type='reservation')
    lease = blazar.lease.create(name,
                                _blazar_datetime(start),
                                _blazar_datetime(end),
                                reservations,
                                [])
    return lease
