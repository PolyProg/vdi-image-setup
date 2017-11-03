#!/bin/sh
# Removes all caches from apt, which can take up to ~250 MB

# Remove the cache itself
apt-get clean

# Remove the package lists (means apt update is necessary before using apt again)
rm -rf '/var/lib/apt/lists'
