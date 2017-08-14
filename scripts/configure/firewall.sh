#!/bin/sh
# Sets HTTP/S firewall rules with a whitelist

if [ $# -eq 0 ]; then
  echo "This scripts expects the allowed URLs as arguments" >&2
  exit 1
fi

# Uninstall the default ufw, we don't need it, let's not have 2 firewalls
apt purge -y ufw

# Allow HTTP/S to all args
for url in "$@"; do
  iptables -A OUTPUT -p tcp -d "$url" --dport 80 -j ACCEPT
  iptables -A OUTPUT -p tcp -d "$url" --dport 443 -j ACCEPT
done

# Allow loopback
iptables -I INPUT 1 -i lo -j ACCEPT

# Allow existing connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Drop rest of HTTP
iptables -A OUTPUT -p tcp --dport 80 -j DROP

# Drop rest of HTTPS
iptables -A OUTPUT -p tcp --dport 443 -j DROP

# Allow vWorkspace Data Collector and RDP, respectively
# These are not necessary now, but useful if this scripts bans more output in the future.
iptables -I INPUT 2 -p tcp --dport 5203 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 3389 -j ACCEPT

# Persist rules
apt install -y iptables-persistent
