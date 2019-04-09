#!/bin/sh
# Python 3.7 language support
# Note that the default on Bionic is 3.6

apt-get install -y python3.7
update-alternatives --install '/usr/bin/python3' 'python3' '/usr/bin/python3.7' 999

# Having 3.7 as the default causes issues with command-not-found during 'apt update', let's just remove it, no need for it anyway
apt purge -y --autoremove command-not-found command-not-found-data python3-commandnotfound
