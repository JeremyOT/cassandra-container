FROM debian:wheezy
MAINTAINER jeremyot@gmail.com

RUN apt-get update && apt-get install procps libsnappy-dev curl libjna-java python-yaml -y; \
    curl -L -b "oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jre-8u65-linux-x64.tar.gz > /tmp/jre.tar.gz; \
    mkdir -p /usr/lib/java; \
    tar -xvzf /tmp/jre.tar.gz -C /usr/lib/java; \
    ln -s /usr/lib/java/jre1.8.0_65/bin/java /usr/bin/java; \
    rm /tmp/jre.tar.gz; \
    curl -L http://debian.datastax.com/debian/repo_key | apt-key add - ; \
    mkdir -p /usr/lib/cassandra; \
    mkdir -p /tmp/cassandra; \
    curl -L http://apache.claz.org/cassandra/2.2.5/apache-cassandra-2.2.5-bin.tar.gz > /tmp/cassandra/apache-cassandra-2.2.5-bin.tar.gz; \
    cd /tmp/cassandra; \
    tar xzvf apache-cassandra-2.2.5-bin.tar.gz; \
    cp -r apache-cassandra-2.2.5/* /usr/lib/cassandra; \
    apt-get remove --purge curl -y; apt-get autoremove -y; apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;
COPY etcdmon /usr/bin/etcdmon
COPY address /usr/bin/address
COPY snapshot /usr/bin/snapshot
COPY load-snapshot /usr/bin/load-snapshot
COPY run.sh /var/cassandra/run.sh
COPY config.py /var/cassandra/config.py
VOLUME ["/var/cassandra/commitlog", "/var/cassandra/saved_caches", "/var/cassandra/data", "/var/cassandra/config", "/var/logs/cassandra"]
EXPOSE 7199 7000 7001 9160 9042
ENTRYPOINT ["/var/cassandra/run.sh"]
