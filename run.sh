#!/bin/bash

case $1 in
  nodetool)
    /usr/lib/cassandra/bin/nodetool "${@:2}"
    ;;
  cqlsh)
    /usr/lib/cassandra/bin/cqlsh "${@:2}"
    ;;
  autoscale)
    ETCD_HOST=$2
    SERVICE_KEY=$3
    if [[ ETCD_HOST != http* ]]; then
      ETCD_HOST="http://${ETCD_HOST}"
    fi
    cp -r /usr/lib/cassandra/conf/* /var/cassandra/config
    /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config "--etcd_seeds=${ETCD_HOST}/v2/keys/${SERVICE_KEY}" "--infer_host=${ETCD_HOST}" "${@:4}"
    CASSANDRA_CONF=/var/cassandra/config /usr/bin/etcdmon -etcd="${ETCD_HOST}" -key="${SERVICE_KEY}/%H" -- /usr/lib/cassandra/bin/cassandra -f
    ;;
  etcdmon)
    ARGS="${@:2}"
    CONFIG=()
    ETCDMON=()
    for i in $ARGS; do
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
