#!/bin/bash
set -x

# required vim-nox and vim-runtime can't be installed due to package dpkg divert
apt-get -y remove vim-tiny ubuntu-minimal

# in order to build vrouter module include kernel headers
apt-get -y install linux-headers-$(uname -r)
