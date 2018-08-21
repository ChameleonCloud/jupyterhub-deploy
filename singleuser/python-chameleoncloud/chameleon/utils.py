from binascii import b2a_hex
from os import urandom

def _rand_name(prefix):
    rand = b2a_hex(urandom(15))
    return '{prefix}-{rand}'.format(prefix=prefix, rand=rand)
