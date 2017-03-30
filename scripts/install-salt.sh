#!/bin/sh

### Installs Salt. Change the configuration below if you need it.

# Get Salt via its bootstrap script
wget -O salt.sh https://bootstrap.saltstack.com
sh salt.sh -P
rm salt.sh

# The bootstrap script starts the minion immediately, but we don't want that
systemctl stop salt-minion
systemctl disable salt-minion

# Configure the minion
rm -r /etc/salt/*
cat > /etc/salt/minion <<EOF
master: master.hc2.ch
verify_env: True
hash_type: sha256
state_verbose: False
tcp_keepalive: True
tcp_keepalive_idle: 60
EOF

# Start the minion only after QDCIP, so that the hostname is correct
# since the machine gets its hostname via LDAP
echo "systemctl enable salt-minion" >> /opt/VDEFORLINUX/Provisioning/qdcip.all
echo "systemctl start salt-minion" >> /opt/VDEFORLINUX/Provisioning/qdcip.all
