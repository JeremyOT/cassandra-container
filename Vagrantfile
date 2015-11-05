vagrant_api_version = "2"
instance_count = 3

if ENV['INSTANCES']
  instance_count = ENV['INSTANCES'].to_i
end

Vagrant.configure(vagrant_api_version) do |config|
  config.vm.define :server do |server|
    server.vm.box = "jeremyot/ubuntu-14.04.3LTS"

    server.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", "2056"]
    end

    server.vm.provider :vmware_fusion do |v, override|
      v.vmx['memsize'] = 2056
      v.vmx['displayName'] = "Cassandra Test"
      v.vmx['numvcpus'] = "2"
    end

    server.vm.provider :vmware_workstation do |v, override|
      v.vmx['memsize'] = 2056
      v.vmx['displayName'] = "Cassandra Test"
      v.vmx['numvcpus'] = "2"
    end

    server.vm.hostname = "cassandratest"
    server.vm.provision :shell, :inline => <<-SCRIPT
      echo 'DOCKER_OPTS="--icc=true --iptables=true ${DOCKER_OPTS}"\n' >> /etc/default/docker
    SCRIPT

    server.vm.provision :docker do |d|
      d.pull_images 'jeremyot/etcd'
      d.build_image '/vagrant', args: '-t cassandra'
    end
    script = <<-SCRIPT
      ETCD=`docker run -d jeremyot/etcd`
      ETCD_ADDR=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ETCD}`
      docker run -d cassandra autoscale "${ETCD_ADDR}:4001" service/cassandra ---Dcassandra.consistent.rangemovement=false
    SCRIPT
    for i in 1..(instance_count-1) do
      script += "\ndocker run -d cassandra autoscale \"${ETCD_ADDR}:4001\" service/cassandra --join ---Dcassandra.consistent.rangemovement=false"
    end
    server.vm.provision :shell, :inline => script
  end
end
