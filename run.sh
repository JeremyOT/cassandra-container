#!/bin/bash

case $1 in
  nodetool)
    /usr/lib/cassandra/bin/nodetool "${@:2}"
    ;;
  cqlsh)
    /usr/lib/cassandra/bin/cqlsh "${@:2}"
    ;;
  etcdmon)
    ARGS="${@:2}"
    CONFIG=()
    ETCDMON=()
    for i in $ARGS; do
      echo "$i"
      if [[ -n "$SPLIT" ]]
      then
       CONFIG+=("$i")
      elif [ "$i" == "--" ]
      then
        SPLIT="split"
      else
       ETCDMON+=("$i")
      fi
    done
    cp -r /usr/lib/cassandra/conf/* /var/cassandra/config
    /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config ${CONFIG[@]}
    CASSANDRA_CONF=/var/cassandra/config /usr/bin/etcdmon ${ETCDMON[@]} -- /usr/lib/cassandra/bin/cassandra -f
    ;;
  *)
    cp -r /usr/lib/cassandra/conf/* /var/cassandra/config
    /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config "${@:2}"
    CASSANDRA_CONF=/var/cassandra/config /usr/lib/cassandra/bin/cassandra -f
    ;;
esac
