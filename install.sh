#!/bin/sh
# Installs the necessary tools to run Xubuntu Core 16.04 on VMware Horizon
# Must be run on an Ubuntu Mini 16.04 x64 image
# Written by Solal Pirelli

### Check for prerequisites
### First the platform, then the stuff that can be changed

if [ ! -f '/etc/lsb-release' ]; then
  echo 'Please run this script on Ubuntu' >&2
  exit 1
fi

. /etc/lsb-release

if [ "$DISTRIB_ID" != 'Ubuntu' ]; then
  echo 'Please run this script on Ubuntu' >&2
  exit 1
fi

if [ "$DISTRIB_RELEASE" != '16.04' ]; then
  echo 'Please run this script on Ubuntu 16.04' >&2
  exit 1
fi

if [ "$(uname -i)" != 'x86_64' ]; then
  echo 'Please run this script on an x64 OS' >&2
  exit 1
fi

NetworkInterface="$(ls /sys/class/net | grep -v lo)"
if [ "$(echo $NetworkInterface | wc -l)" -ne '1' ]; then
  echo 'Please run this script in a machine with only 1 interface (apart from loopback)' >&2
  exit 1
fi

if [ "$(id -u)" != '0' ]; then
  echo 'Please run this script as root' >&2
  exit 1
fi

if [ ! -d 'install' ]; then
  echo 'Please run this script from its containing folder.' >&2
  exit 1
fi

if [ ! -f '/opt/horizon-client.tar.gz' ]; then
  echo 'Please put the VMware Horizon Client in /opt/horizon-client.tar.gz' >&2
  exit 1
fi

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <AD user> <AD user password> <AD domain> <AD computer OU>" >&2
  exit 1
fi


### Perform the installation, in modular steps

./install/xubuntu-minimal.sh
./install/ad-auth.sh "$1" "$2" "$3" "$4"
./install/horizon-client.sh
