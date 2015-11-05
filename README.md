Cassandra
=========

Cassandra 2.0.16

Usage
-----
In the simplest case, you can start a single node with `docker run jeremyot/cassandra`. The new node
will be configured to listen on the address asigned to the eth0 interface and will accept RPC connectons
on all interfaces.

Deploying a cluster is almost as easy. The container includes tooling to automatically bootstrap a cluster
using etcd. For example:

```bash
ETCD=`docker run -d jeremyot/etcd`
ETCD_ADDR=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ETCD}`
docker run -d jeremyot/cassandra autoscale "${ETCD_ADDR}:4001" service/cassandra
docker run -d jeremyot/cassandra autoscale "${ETCD_ADDR}:4001" service/cassandra --join
docker run -d jeremyot/cassandra autoscale "${ETCD_ADDR}:4001" service/cassandra --join
```

will start a three node cassandra cluster. You can verify with

```bash
CASSANDRA_ADDR=`docker inspect --format "{{ .NetworkSettings.IPAddress }}" \`docker ps -lq\``
docker run -it --rm jeremyot/cassandra nodetool -h $CASSANDRA_ADDR status
```

You should see a normal `nodetool status` printout displaying information on all three nodes.

To persist data across restarts, be sure to mount Cassandra's data directory with `-v /host/path/to/cassandra:/var/cassandra`.

Configuration
-------------

Cassandra may be configured by passing arguments when starting the container. A YAML library is included which will convert
arbitrary arguments to YAML and write to `cassandra.yaml`. YAML paths passed as arguments are flattened and prefixed with `--`.

For example: `--rpc_address=0.0.0.0` becomes `rpc_address: 0.0.0.0` and `--some.key=value` becomes `some: {key: value}`. To
support complex structures, values may also be passed as YAML strings. `--some.key="{k1: [1, 2, 3], k2: [2, 3, 4]}"` becomes

```yaml
some:
  key:
    k1: [1, 2, 3]
    k2: [2, 3, 4]
```

### Special parameters

For convenience, a few special arguments are supported:

- `--listen_interface="etho"`: configures cassandra to bind to the specified interface.
- `--seeds="10.0.0.2, 10.0.0.3"`: a shortcut for using SimpleSeedProvider with the specified seeds.
- `--etc_seeds="127.0.0.1:4001/v2/keys/service/key"`: queries etcd for the initial list of keys, registered at the specified path.
  (used by autoscale). Will start as a standalone node if no results are found.
- `--logger=INFO,stdout,R`: sets the logger in `log4j-server.properties`.
- `--infer_address=google.com`: uses a connection to the specified address to infer which address Cassandra should bind to. useful
   for containers with multiple ethernet devices. Allows you to specify a remote host (e.g. another node in the Cassandra cluster)
   and know that Cassandra will be accessible to it.
- `--join`: Used with `--etc_seeds` to prevent bootstrapping as a standalone node. Will wait until some seeds are returned from etcd
   before continuing.

Tools
-----
Along with Cassandra, there are a few tools included with this container. They are as follows:

- `autoscale`: as shown above, uses etcd to bootstrap a cluster. May be followed by the standard cassandra configuration arguments.
- `etcdmon`: a subcomponent of `autoscale`, uses `etcdmon` (https://github.com/JeremyOT/etcdmon) to register the server's
  status with etcd. Additional arguments may be passed in the form `<ETCDMON_PARAMS> -- <CASSANDRA_PARAMS>`.
- `nodetool`: runs `nodetool` and supports any standard `nodetool` arguments.
- `cqlsh`: runs `cqlsh` and supports any standard `cqlsh` arguments.

#### `autoscale`

Autoscaling may be used in a few different ways. Called with `autoscale 10.0.0.8:4001 service/cassandra`, Cassandra will infer its
`listen_address` by making a connection to `10.0.0.8`. It will then attempt to retrieve a list of seeds by querying
`http://10.0.0.8:4001/v2/keys/service/cassandra`, using its own address as the only seed if none are found. Finally, etcdmon will
update `http://10.0.0.8:4001/v2/keys/service/cassandra/<node_address>` with `value={"host": <node_address>}&ttl=30`, pinging etcd every 10
seconds. Alternatively `autoscale 10.0.0.8:4001 service/cassandra <interface_name>` may be used to bind to the specified interface,
and `autoscale 10.0.0.8:4001 service/cassandra <remote_address>` will infer the address by making a connection to the specified
remote address. If the third argument does not begin with `--`, it will first be treated as an interface, then used to infer
the address if no matching interface is found. In all three cases, standard configuration options may be appended.

Note: The address executable, used by the autoscale commands, is built from https://github.com/JeremyOT/address. It is pre-compiled to avoid the need to install Go inside the container.

Snapshots
---------

This container can be used to create and export Cassandra snapshots as tar files (optionall compressed) with the following command:

```bash
docker run -i --volumes-from=<running_cassandra_container_id> --net=container:<running_cassandra_container_id> jeremyot/cassandra snapshot <options> (<keyspace> ... ) (> <output.tar>)
```

Additional options let you specify compression, keyspaces and/or an output file to write to instead of stdout.

Use `docker run -i jeremyot/cassandra snapshot --help` for more information.
