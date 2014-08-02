#!/bin/bash

case $1 in
  nodetool)
    /usr/lib/cassandra/bin/nodetool "${@:2}"
    ;;
  cqlsh)
    /usr/lib/cassandra/bin/cqlsh "${@:2}"
    ;;
  *)
    cp -r /usr/lib/cassandra/conf/* /var/cassandra/config
    /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config "${@:2}"
    CASSANDRA_CONF=/var/cassandra/config /usr/lib/cassandra/bin/cassandra -f
    ;;
esac
