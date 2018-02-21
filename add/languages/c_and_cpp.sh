#!/bin/sh
# C and C++ language support
# GCC 7 backport for Ubuntu 16.04, which supports much more than the default ones

NeedSpc=0
if [ ! -x "$(command -v add-apt-repository)" ]; then
  apt-get install -y software-properties-common
  NeedSpc=1
fi


# Install G++7, and thus GCC7 and CPP7
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt-get update
apt-get install -y g++-7

# Set them as defaults
for Prog in 'g++' 'gcc' 'cpp'; do
  update-alternatives --install "/usr/bin/$Prog" "$Prog" "/usr/bin/$Prog-7" 999
done

# Install GDB to debug it
apt-get install -y gdb


if [ $NeedSpc -eq 1 ]; then
  apt-get purge --autoremove -y software-properties-common
fi
