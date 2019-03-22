#!/bin/sh
# C and C++ language support, via GCC 8

# Install G++, and thus GCC and CPP
apt-get install -y g++-8

# Set them as defaults
for Prog in 'g++' 'gcc' 'cpp'; do
  update-alternatives --install "/usr/bin/$Prog" "$Prog" "/usr/bin/$Prog-8" 999
done

# Install GDB to debug it
apt-get install -y gdb
