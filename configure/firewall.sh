#!/bin/sh
# Sets HTTP/S firewall rules with a whitelist

if [ $# -eq 0 ]; then
  echo "This scripts expects the allowed URLs as arguments" >&2
  exit 1
fi

# Uninstall the default ufw, we don't need it, let's not have 2 firewalls
apt-get purge -y ufw

# Allow HTTP/S to all args
for url in "$@"; do
  iptables -A OUTPUT -p tcp -d "$url" --dport 80 -j ACCEPT
  iptables -A OUTPUT -p tcp -d "$url" --dport 443 -j ACCEPT
done

# Reject rest of HTTP/S (reject, not drop, so it's clear to users that it will not work)
iptables -A OUTPUT -p tcp --dport 80 -j REJECT
iptables -A OUTPUT -p tcp --dport 443 -j REJECT

# Persist rules (with debconf-set-selections to make it unattended)
echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' | debconf-set-selections
echo 'iptables-persistent iptables-persistent/autosave_v6 boolean true' | debconf-set-selections
apt-get install -y iptables-persistent
