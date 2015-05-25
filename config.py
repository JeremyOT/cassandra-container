#!/usr/bin/env python
import yaml
import os
import re
import json
import subprocess
import sys
from urllib2 import urlopen
from time import time, sleep

# prevent buffering
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

CONFIG_FILE = 'cassandra.yaml'
ENV_CONFIG_FILE = 'cassandra-env.sh'

input_path = sys.argv[1]
output_path = sys.argv[2]

# properties used by configuration itself
config_properties = {
  'join_wait': 10,
  'join_timeout': float("inf"),
  'join': False,
  'self_seed': True,
  'seeds': '',
  'java_opts': []
}

with open(os.path.join(input_path, CONFIG_FILE), 'rb') as f:
  config = yaml.load(f.read())

with open(os.path.join(input_path, ENV_CONFIG_FILE), 'rb') as f:
  env_config = f.read()

def _set(config, prop, value):
  d = config
  path = prop.split('.')
  for p in path[:-1]:
    if p not in d:
      d[p] = {}
    d = d[p]
  if value is None:
    d.pop(path[-1], None)
  else:
    d[path[-1]] = value

def _get(config, prop, default=None):
  d = config
  path = prop.split('.')
  for p in path[:-1]:
    if p not in d:
      d[p] = {}
    d = d[p]
  return d.get(path[-1], default)

def set_seeds(config, prop, seeds):
  config_properties['self_seed'] = False
  config['seed_provider'] = [{'class_name': 'org.apache.cassandra.locator.SimpleSeedProvider', 'parameters': [{'seeds': str(seeds)}]}]
  config_properties['seeds'] = str(seeds)

def set_etcd_seeds(config, prop, url):
  address = _get(config, 'listen_address')
  start = time()
  while 1:
    try:
      root = json.loads(urlopen(url).read())
      nodes = root['node'].get('nodes', [])
      if not nodes:
        raise Exception('No seeds registered.')
      seeds = ','.join([json.loads(n['value'])['host'] for n in nodes])
      set_seeds(config, 'seeds',  seeds)
      print "Set seeds:", seeds
      return
    except Exception as e:
      if not config_properties['join']:
        print "Failed to query seeds. Falling back to %s." % address, e
        set_seeds(config, 'seeds', address)
        return
      elif time() - start < config_properties['join_timeout']:
        print "Failed to query seeds. Waiting %s sec." % config_properties['join_wait'], e
        sleep(config_properties['join_wait'])
      else:
        print "Failed to query seeds within timeout. Exiting.", e
        exit(1)

def infer_address(config, prop, remote):
  try:
    address = subprocess.Popen(['/usr/bin/address', '-r', remote], stdout=subprocess.PIPE).stdout.read().strip()
    print "Inferred address:", address
  except Exception as e:
    print "Failed to infer address. Falling back to 127.0.0.1", e
  _set(config, 'listen_address', address)

def set_join(config, prop, timeout):
  print 'Configured to wait for seed nodes.'
  config_properties['join'] = True
  if timeout:
    config_properties['join_timeout'] = float(timeout)

def set_listen_interface(config, prop, interface):
  try:
    address = subprocess.Popen(["/usr/bin/address", "-i", interface], stdout=subprocess.PIPE).stdout.read().strip()
    _set(config, 'listen_address', address)
  except Exception as e:
    print "Failed to find address for interface %s" % interface, e
    exit(1)

def set_property(config, prop, value):
  data = yaml.load(value)
  _set(config, prop, data)

_set(config, 'commitlog_directory', '/var/cassandra/commitlog')
_set(config, 'saved_caches_directory', '/var/cassandra/saved_caches')
_set(config, 'data_file_directories', ['/var/cassandra/data'])
_set(config, 'rpc_address', '0.0.0.0')
set_listen_interface(config, 'listen_interface', 'eth0')

PRIORITY = ['infer_address', 'listen_interface', 'listen_address', 'join', 'etcd_seeds', 'seeds']

HANDLERS = {
  'listen_interface': set_listen_interface,
  'seeds': set_seeds,
  'etcd_seeds': set_etcd_seeds,
  'infer_address': infer_address,
  'join': set_join,
}

properties = {k: v for k, v in ((j[0], len(j) > 1 and j[1] or None) for j in (i.strip()[2:].split('=') for i in sys.argv[3:] if i.startswith('--')))}

for k in PRIORITY:
  if k in properties:
    value = properties[k]
    del properties[k]
    HANDLERS.get(k, set_property)(config, k, value)

for prop, value in properties.iteritems():
  if not prop:
      continue
  if prop.startswith('-D'):
    config_properties['java_opts'].append('%s=%s' % (prop, value))
    continue
  HANDLERS.get(prop, set_property)(config, prop, value)

if config_properties['self_seed']:
  address = _get(config, 'listen_address')
  set_seeds(config, 'seeds', address)

if properties:
  print 'Configured Cassandra:'
  for k, v in properties.iteritems():
    print '  %s = %s' % (k, v)

print 'Listening on %s' % _get(config, 'listen_address')
print 'RPC address %s' % _get(config, 'rpc_address')
print 'Seeding with %s' % config_properties['seeds']

if config_properties['java_opts']:
  env_config += '\nJVM_OPTS="$JVM_OPTS %s"\n' % ' '.join(config_properties['java_opts'])

with open(os.path.join(output_path, CONFIG_FILE), 'wb') as f:
  f.write(yaml.dump(config))

with open(os.path.join(output_path, ENV_CONFIG_FILE), 'wb') as f:
  f.write(env_config)
