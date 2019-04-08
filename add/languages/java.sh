#!/bin/sh
# Java language support
# Note that as of 2019-03-22, the openjdk-11-jdk package contains JDK 10...
# See https://bugs.launchpad.net/ubuntu/+source/saaj/+bug/1814133
# So we instead get a PPA from the Ubuntu OpenJDK team
# Also we don't use add-apt-repository to install the PPA cause that conflicts with Python 3.7
# TODO: This should just be apt-get install -y openjdk-11-jdk when they fix that...

# Needed to install a key
apt-get install -y gnupg

echo 'deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu bionic main' >> '/etc/apt/sources.list'
echo 'deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu bionic main' >> '/etc/apt/sources.list'
apt-key adv --keyserver 'keyserver.ubuntu.com' --recv-keys 'DA1A4A13543B466853BAF164EB9B1D8886F44E2A'

apt-get update
apt-get install -y openjdk-11-jdk
