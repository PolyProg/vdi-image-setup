#!/bin/sh
# Removes all packages that aren't needed any more

apt-get autoremove -y --purge
