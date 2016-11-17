#!/bin/bash
# Redirect all outputs
exec > >(tee -i /tmp/mk-bootstrap.log) 2>&1
set -x

# get the slave node's admin ip address as defined in the reclass model
export admin_ip_address=$(salt-call --out=text pillar.get _param:single_address | sed -n -e 's/^.*: \(\)/\1/p' | tr -d '\n')

# configure slave node's admin ip address
ip addr a $admin_ip_address/24 dev weave
