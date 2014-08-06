#!/bin/bash

case $1 in
  nodetool)
    /usr/lib/cassandra/bin/nodetool "${@:2}"
    ;;
  cqlsh)
    /usr/lib/cassandra/bin/cqlsh "${@:2}"
    ;;
  autoscale)
    ETCD_ADDR=$2
    SERVICE_KEY=$3
    REMOTE_ADDR=$2
    if [[ ETCD_ADDR != http* ]]; then
      ETCD_ADDR="http://${ETCD_ADDR}"
    fi
    if [[ -n "$4" ]] && [[ "$4" != "--" ]]; then
      REMOTE_ADDR=$4
      ARGS=("${@:5}")
    else
      ARGS("${@:4}")
    fi
    cp -r /usr/lib/cassandra/conf/* /var/cassandra/config
    /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config "--etcd_seeds=${ETCD_ADDR}/v2/keys/${SERVICE_KEY}" "--infer_host=${REMOTE_ADDR}" "${ARGS[@]}"
    CASSANDRA_CONF=/var/cassandra/config /usr/bin/etcdmon -etcd="${ETCD_ADDR}" -remote="${REMOTE_ADDR}" -key="${SERVICE_KEY}/%H" -- /usr/lib/cassandra/bin/cassandra -f
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
