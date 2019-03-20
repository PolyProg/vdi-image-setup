#!/bin/sh
# Installs Atom

wget https://packagecloud.io/AtomEditor/atom/gpgkey -O - | apt-key add -
echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list
apt-get update

apt-get install -y atom
