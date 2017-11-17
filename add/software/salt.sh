#!/bin/sh
# Installs Salt. Single argument to this script is the master URL.

if [ $# -eq 0 ]; then
  echo "This script takes the Salt master URL as argument" >&2
  exit 1
fi

# Salt will install software-properties-common on its own, we need to clean up afterwards
NeedSpc=0
if [ ! -x "$(command -v add-apt-repository)" ]; then
  NeedSpc=1
fi

# Get Salt via its bootstrap script
wget -O 'salt.sh' 'https://bootstrap.saltstack.com'

# Run the script
# -X == don't start the minion immediately
sh 'salt.sh' -X
rm 'salt.sh'

# Configure the minion
rm -r '/etc/salt/'*
cat > '/etc/salt/minion' <<EOF
master: $1
verify_env: True
hash_type: sha256
state_verbose: False
tcp_keepalive: True
tcp_keepalive_idle: 60
EOF

# Start the minion only after the machine is configured, so that the hostname is correct
systemctl daemon-reload
echo 'systemctl start --now salt-minion' >> '/opt/install-continuation.sh'


if [ $NeedSpc -eq 1 ]; then
  apt-get purge --autoremove -y software-properties-common
fi
