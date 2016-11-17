#!/bin/bash
# Redirect all outputs
exec > >(tee -i /tmp/mk-bootstrap.log) 2>&1
set -x

echo "Installing Docker ..."
apt-get clean
apt-get update
apt-get install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-${ubuntu_release} main" | sudo tee /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-engine
service docker start

echo "Installing Weave ..."
curl -L git.io/weave -o /usr/local/bin/weave
chmod a+x /usr/local/bin/weave
weave launch ${private_ip_address} --ipalloc-range 172.16.10.0/24
