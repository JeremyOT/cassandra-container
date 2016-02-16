#!/bin/bash

case $1 in
  nodetool)
    /usr/lib/cassandra/bin/nodetool "${@:2}"
    ;;
  cqlsh)
    /usr/lib/cassandra/bin/cqlsh "${@:2}"
    ;;
  sstableloader)
    /usr/lib/cassandra/bin/sstableloader "${@:2}"
    ;;
  snapshot)
    /usr/bin/snapshot "${@:2}"
    ;;
  load-snapshot)
    /usr/bin/load-snapshot "${@:2}"
    ;;
  autoscale)
    ETCD_ADDR=$2
    SERVICE_KEY=$3
    REMOTE_ADDR_OR_IFACE=$2
    if [[ ETCD_ADDR != http* ]]; then
      ETCD_ADDR="http://${ETCD_ADDR}"
    fi
    if [[ -n "$4" ]] && [[ "$4" != --* ]]; then
      REMOTE_ADDR_OR_IFACE=$4
      ADDR=`/usr/bin/address -i ${REMOTE_ADDR_OR_IFACE}`
      ARGS=("${@:5}")
    elif [[ "$4" == "--" ]]; then
      ARGS=("${@:5}")
    else
      ARGS=("${@:4}")
    fi
    cp -r /usr/lib/cassandra/conf/* /var/cassandra/config
    if [[ -n "$ADDR" ]]; then
      /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config "--etcd_seeds=${ETCD_ADDR}/v2/keys/${SERVICE_KEY}" "--listen_address=${ADDR}" "${ARGS[@]}"
      CASSANDRA_CONF=/var/cassandra/config /usr/bin/etcdmon -etcd="${ETCD_ADDR}" -host="${ADDR}" -key="${SERVICE_KEY}/%H" -- /usr/lib/cassandra/bin/cassandra -f
    else
      /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config "--etcd_seeds=${ETCD_ADDR}/v2/keys/${SERVICE_KEY}" "--infer_address=${REMOTE_ADDR_OR_IFACE}" "${ARGS[@]}"
      CASSANDRA_CONF=/var/cassandra/config /usr/bin/etcdmon -etcd="${ETCD_ADDR}" -remote="${REMOTE_ADDR_OR_IFACE}" -key="${SERVICE_KEY}/%H" -- /usr/lib/cassandra/bin/cassandra -f
    fi
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
    /var/cassandra/config.py /usr/lib/cassandra/conf /var/cassandra/config "${@:1}"
    CASSANDRA_CONF=/var/cassandra/config /usr/lib/cassandra/bin/cassandra -f
    ;;
esac
