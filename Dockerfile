FROM ubuntu:14.04
MAINTAINER jeremyot@yix.io

RUN apt-get update && apt-get install libtool autoconf automake build-essential g++ uuid-dev curl -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get update && apt-get install libsnappy-dev pkg-config software-properties-common -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN add-apt-repository -y ppa:webupd8team/java
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
RUN echo deb http://debian.datastax.com/community stable main >> /etc/apt/sources.list.d/cassandra.list
RUN curl -L http://debian.datastax.com/debian/repo_key | apt-key add -
RUN apt-get update && apt-get install oracle-java7-installer libjna-java python-yaml -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mkdir -p /usr/lib/cassandra; mkdir -p /tmp/cassandra; wget -O /tmp/cassandra/apache-cassandra-2.0.9-bin.tar.gz http://apache.claz.org/cassandra/2.0.9/apache-cassandra-2.0.9-bin.tar.gz; cd /tmp/cassandra; tar -xvf apache-cassandra-2.0.9-bin.tar.gz; cp -r apache-cassandra-2.0.9/* /usr/lib/cassandra; cd /tmp; rm -r cassandra
COPY etcdmon /usr/bin/etcdmon
COPY address /usr/bin/address
COPY run.sh /var/cassandra/run.sh
COPY config.py /var/cassandra/config.py
VOLUME ["/var/cassandra/commitlog", "/var/cassandra/saved_caches", "/var/cassandra/data", "/var/cassandra/config", "/var/logs/cassandra"]
EXPOSE 7199 7000 7001 9160 9042
ENTRYPOINT ["/var/cassandra/run.sh"]
