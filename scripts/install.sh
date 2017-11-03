#!/bin/sh
# Installs the necessary tools to run Xubuntu Core 16.04 on Dell vWorkspace
# Must be run on an Ubuntu Mini 16.04 x64 image
# Written by Solal Pirelli
# Original vWorkspace scripts written by Stephen Yorke (Dell)

### Check for prerequisites
### First the platform, then the stuff that can be changed

if [ ! -e '/usr/bin/lsb_release' ]; then
  echo 'Please run this script under Ubuntu' >&2
  exit 1
fi

case "$(lsb_release -d)" in
  *'Ubuntu 16.04'*)
    :
    ;;
  *)
    echo 'Please run this script under Ubuntu 16.04' >&2
    exit 1
    ;;
esac

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

if [ ! -d '/opt/VDEFORLINUX' ]; then
  echo 'Please put the vWorkspace VDEFORLINUX folder in /opt/VDEFORLINUX' >&2
  exit 1
fi

if [ ! -d 'install' ]; then
  echo 'Please run this script from its containing folder.' >&2
  exit 1
fi


### Perform the installation, in modular steps

./install/xubuntu-minimal.sh
./install/ad-auth.sh
./install/xrdp.sh
./install/qdcsvc-deps.sh
./install/qdcsvc.sh
./install/continuation.sh
