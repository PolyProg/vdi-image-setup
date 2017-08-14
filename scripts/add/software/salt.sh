#!/bin/sh
# Installs Salt. Single argument to this script is the master URL.

if [ $# -eq 0 ]; then
  echo "This script takes the Salt master URL as argument" >&2
  exit 1
fi

# Get Salt via its bootstrap script
wget -O 'salt.sh' 'https://bootstrap.saltstack.com'
sh 'salt.sh' -P
rm 'salt.sh'

# The bootstrap script starts the minion immediately, but we don't want that
systemctl disable --now salt-minion

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

# TODO have a proper hook
# Start the minion only after the machine is configured, so that the hostname is correct
echo 'systemctl start --now salt-minion' >> '/opt/install-continuation.sh'
