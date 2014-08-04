#!/usr/bin/env python
import yaml
import os
import re
import json
from urllib2 import urlopen
from sys import argv

CONFIG_FILE = 'cassandra.yaml'
LOGGER_FILE = 'log4j-server.properties'

input_path = argv[1]
output_path = argv[2]

with open(os.path.join(input_path, CONFIG_FILE), 'rb') as f:
  config = yaml.load(f.read())

def _set(config, prop, value):
  d = config
  path = prop.split('.')
  for p in path[:-1]:
    if p not in d:
      d[p] = {}
    d = d[p]
  d[path[-1]] = value

def set_seeds(config, prop, seeds):
  config['seed_provider'] = [{'class_name': 'org.apache.cassandra.locator.SimpleSeedProvider', 'parameters': [{'seeds': seeds}]}]

def set_etcd_seeds(config, prop, url):
  root = json.loads(urlopen(url).read())
  nodes = root['node'].get('nodes', [])
  seeds = [n['value'] for n in nodes]
  set_seeds(config, prop, seeds and ','.join(seeds) or '127.0.0.1')

def set_logger(config, prop, logger):
  with open(os.path.join(input_path, 'log4j-server.properties'), 'rb') as f:
    logger_config = f.read()
  logger_config = re.sub(r'log4j\.rootLogger=.*', 'log4j.rootLogger=%s' % logger, logger_config)
  with open(os.path.join(output_path, 'log4j-server.properties'), 'wb') as f:
    f.write(logger_config)

def set_property(config, prop, value):
  data = yaml.load(value)
  _set(config, prop, data)

_set(config, 'commitlog_directory', '/var/cassandra/commitlog')
_set(config, 'saved_caches_directory', '/var/cassandra/saved_caches')
_set(config, 'data_file_directories', ['/var/cassandra/data'])
set_logger(None, None, 'INFO,R') # default INFO,stdout,R

HANDLERS = {
  'seeds': set_seeds,
  'etcd_seeds': set_etcd_seeds,
  'logger': set_logger
}

properties = {k: v for k, v in (i.strip()[2:].split('=') for i in argv[3:] if i.startswith('--'))}
for prop, value in properties.iteritems():
  HANDLERS.get(prop, set_property)(config, prop, value)

if properties:
  print 'Configured Cassandra:'
  for k, v in properties.iteritems():
    print '  %s = %s' % (k, v)

with open(os.path.join(output_path, CONFIG_FILE), 'wb') as f:
  f.write(yaml.dump(config))
