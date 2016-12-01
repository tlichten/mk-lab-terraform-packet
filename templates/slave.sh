#!/bin/bash
echo "Preparing base OS ..."

which wget >/dev/null || (apt-get update; apt-get install -y wget)

echo "deb [arch=amd64] http://apt.tcpcloud.eu/nightly/ trusty main security extra tcp tcp-salt" > /etc/apt/sources.list
curl http://apt.tcpcloud.eu/public.gpg | apt-key add -

echo "deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/2016.3 trusty main" > /etc/apt/sources.list.d/saltstack.list
curl https://repo.saltstack.com/apt/ubuntu/14.04/amd64/2016.3/SALTSTACK-GPG-KEY.pub | apt-key add -

apt-get clean
apt-get update
apt-get install -y salt-minion

echo "id: $node_name" >> /etc/salt/minion
echo "master: $config_host" >> /etc/salt/minion
rm -f /etc/salt/pki/minion/minion_master.pub
service salt-minion restart
echo "Showing node metadata..."
salt-call --no-color pillar.data
echo "Running complete state ..."
salt-call state.sls linux,openssh,salt -l info
