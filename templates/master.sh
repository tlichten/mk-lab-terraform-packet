#!/bin/bash
# Redirect all outputs
exec > >(tee -i /tmp/mk-bootstrap.log) 2>&1
set -x
echo "Preparing base OS ..."

which wget >/dev/null || (apt-get update; apt-get install -y wget)

echo "deb [arch=amd64] http://apt.tcpcloud.eu/nightly/ xenial main security extra tcp" > /etc/apt/sources.list
curl http://apt.tcpcloud.eu/public.gpg | apt-key add -

echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2016.3 xenial main" > /etc/apt/sources.list.d/saltstack.list
curl https://repo.saltstack.com/apt/ubuntu/16.04/amd64/2016.3/SALTSTACK-GPG-KEY.pub | apt-key add -

apt-get clean
apt-get update

echo "Installing salt master ..."
apt-get install -y reclass
apt-get install -y salt-master

[ ! -d /root/.ssh ] && mkdir -p /root/.ssh
cat << 'EOF' > /root/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAqdHr4zmivHPEimCuK9vtATe4PvGEr0Np/JxYDlEQsr5Cajh4
tajxmZrjdAnJWFXVbmYl21sN1cUW0ltxB+9+lc4GNVNCZqE4kmpsyx2lrF7xCFvF
Qou26JYud/UCT9IpCYgWjQIGSC8gq1TzfgOpn6rWnLNSl3WdM5TKtQT7RXIkdSUw
kXFbObz9lsM+ULWNozCId2osJHj4zE0D3H5odU5DpcWLuSG0MmdxtWoQNJjSiPWt
HbRdvNmr/xeqcAfzdUdZxGf/VbXDdiNZn9TVv7UxxBHE812KNUf/Cvb5agDfEL7x
i2bWXbhr4jVTaDVr6MWl8Q7fAj79gdjQnUBWaQIDAQABAoIBAFU3kU6yIna9BViH
UX+S2ijtRBjZ68JjavEnp4xvo5h+nydcdT57q9lv/0nAi3g3gmXm/oJH+/ZU87HV
zy+zP+t+umDSChUkPBZFL5jxpKyN7BhMrP1KzRuEGYd6vJE/nfY5g095P5vDgnpX
o+SNg/YqrY1u8zgr/hnfRaV2/XyIDEEcQXTHseWTnnMQnULFU88xL8yq8ACT5GhK
7A9m5ukfcU6d/fs/psz5Yqw5IQsWbv1yJ3/FKufPHlo2Nzh3/3eDAZUXvaBgf1so
FWFpHtkry3OXOGaZ98HgF9hL0twS0pzMvuypdGUQAt6nyB1N5re4LK/MAOddqwEc
1+NQzfECgYEA2ryEf0GLJdtiYs3F4HbwTwJVIXdyWv7kjYGeMkutzzAjXl6wx8aq
kfqLJ7x7UkR5unZ1ajEbKBciAlSuFA+Gikn6a4Lv8h87aSnHpPd/2VSitRlI/gW7
w4U4CL3Br1JyonU5WA7VYfTow7KnHBhdwm27RMA9uosyIpveQRpqSG0CgYEAxsAS
wCQKrhuPq2YtGtFR7K4BL+N+0E1Vq6h49u1ukcgUe0GHVD3VzBypNCv7rWEVHzAg
biCVi7PCjzZYW4fYZmzVD4JbFLVGOUu7aJwLaE4wDe72DNr6YZhcS+Ta98BP+x0q
Wt34JNPDabRPfhXfhiCqnWjjod+4Zqx4VJVNgG0CgYB5EXL8xJhyAbW5Hk/x56Mm
+BGKjoR7HS3/rMiU6hJv5SMObrbGPI3YcqZm/gn8BO6jaEGg30E6tWMbiyc270j2
be/vZe/NQcAuevOHuX3IGvJb7nzaLO46UBgtrmnv0mCkzuFIfh1ZNKdI+i9Ie6wZ
m4bVjNod0EGVqlQgELDXGQKBgB+NNmzSS++/6FrpaZesSzkrlnynvOYMoOETacCp
iLgT70xx5q308w/oLORfZyDrHJNK7JsPCS6YZvadRgGh2zTHajuAEj2DWZaW8zV0
MEtqvi44FU+NI9qCeYSC3FAgc5IF20d5nX8bLxaEzWnSxx1f6jX7BMgZ4AhMsP2c
hiUxAoGAFaxn+t9blIjqUiuh0smSYFhLBVPZveYHQDmQYERjktptBd3X95fGnSKh
iDe2iPGyud2+Yu4X/VjHLh/MRru+ZXvPXw1XwEqX93q8a1n283ul0Rl9+KKKOVHR
eecTjI/BfXBf33mPRKny3xuHw6uwta2T3OXky9IhqYS1kkHiZWA=
-----END RSA PRIVATE KEY-----
EOF
chmod 400 /root/.ssh/id_rsa

cat << 'EOF' > /etc/salt/master.d/master.conf
file_roots:
  base:
  - /usr/share/salt-formulas/env
pillar_opts: False
open_mode: True
reclass: &reclass
  storage_type: yaml_fs
  inventory_base_uri: /srv/salt/reclass
ext_pillar:
  - reclass: *reclass
master_tops:
  reclass: *reclass
EOF

echo "Configuring reclass ..."
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
git clone $reclass_address /srv/salt/reclass -b $reclass_branch
mkdir -p /srv/salt/reclass/classes/service

sed -i "s/cfg.mk22-lab-basic.local/$private_ip/" /srv/salt/reclass/classes/cluster/mk22_lab_basic/fuel/config.yml


FORMULA_PATH=${FORMULA_PATH:-/usr/share/salt-formulas}
FORMULA_REPOSITORY=${FORMULA_REPOSITORY:-deb [arch=amd64] http://apt.tcpcloud.eu/nightly/ trusty tcp-salt}
FORMULA_GPG=${FORMULA_GPG:-http://apt.tcpcloud.eu/public.gpg}

echo "Configuring salt master formulas ..."
which wget > /dev/null || (apt-get update; apt-get install -y wget)

echo "${FORMULA_REPOSITORY}" > /etc/apt/sources.list.d/tcpcloud_salt.list
curl "${FORMULA_GPG}" | apt-key add -

apt-get clean
apt-get update

[ ! -d /srv/salt/reclass/classes/service ] && mkdir -p /srv/salt/reclass/classes/service

declare -a formula_services=("linux" "reclass" "salt" "openssh" "ntp" "git" "nginx" "collectd" "sensu" "heka" "sphinx" "keystone" "mysql")

for formula_service in "${formula_services[@]}"; do
    echo -e "\nConfiguring salt formula ${formula_service} ...\n"
    [ ! -d "${FORMULA_PATH}/env/${formula_service}" ] && \
        apt-get install -y salt-formula-${formula_service}
    [ ! -L "/srv/salt/reclass/classes/service/${formula_service}" ] && \
        ln -s ${FORMULA_PATH}/reclass/service/${formula_service} /srv/salt/reclass/classes/service/${formula_service}
done

[ ! -d /srv/salt/env ] && mkdir -p /srv/salt/env
[ ! -L /srv/salt/env/prd ] && ln -s ${FORMULA_PATH}/env /srv/salt/env/prd

[ ! -d /etc/reclass ] && mkdir /etc/reclass
cat << 'EOF' > /etc/reclass/reclass-config.yml
storage_type: yaml_fs
pretty_print: True
output: yaml
inventory_base_uri: /srv/salt/reclass
EOF

echo "Configuring salt minion ..."
[ ! -d /etc/salt/minion.d ] && mkdir -p /etc/salt/minion.d
cat << EOF > /etc/salt/minion.d/minion.conf
id: $node_name
master: 127.0.0.1
EOF
apt-get install -y salt-minion

echo "Restarting services ..."
systemctl restart salt-master
systemctl restart salt-minion

echo "Showing system info and metadata ..."
salt-call --no-color grains.items
salt-call --no-color pillar.data

echo "Running complete state ..."
salt-call --no-color state.sls linux,openssh -l info
salt-call --no-color state.sls reclass -l info
salt-call --no-color state.sls salt.master.service -l info
salt-call --no-color state.sls salt.master,salt.minion.ca -l info
systemctl restart salt-minion

reclass-salt --top
salt-call --no-color state.sls salt.minion.cert -l info
