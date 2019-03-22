#!/bin/sh
# Scala language support
# Unfortunately the 'scala' package is 2.11, we want the latest

wget -O 'scala.deb' 'https://downloads.lightbend.com/scala/2.12.8/scala-2.12.8.deb'
dpkg -i 'scala.deb'
apt-get install -f -y
rm 'scala.deb'
