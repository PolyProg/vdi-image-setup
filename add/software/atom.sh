#!/bin/sh
# Installs Atom

wget -O 'atom.deb' 'https://atom.io/download/deb'
dpkg -i 'atom.deb'
apt-get install -f -y
rm 'atom.deb'
