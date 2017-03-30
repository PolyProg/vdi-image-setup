#!/bin/sh
# Sets HTTP/S firewall rules with a whitelist

if [ $# -eq 0 ]; then
  echo "No arguments given, all HTTP/S traffic will be banned"
else
  echo "HTTP/S traffic will only be allowed for $@"
fi

# Allow HTTP/S to all args
for url in "$@"; do
  iptables -A OUTPUT -p tcp -d $url --dport 80 -j ACCEPT
  iptables -A OUTPUT -p tcp -d $url --dport 443 -j ACCEPT
done

# Allow loopback
iptables -I INPUT 1 -i lo -j ACCEPT

# Allow existing connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Drop rest of HTTP
iptables -A OUTPUT -p tcp --dport 80 -j DROP

# Drop rest of HTTPS
iptables -A OUTPUT -p tcp --dport 443 -j DROP

# Persist rules
apt install -y iptables-persistent
