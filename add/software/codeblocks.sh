#!/bin/sh
# Installs Code::Blocks

NeedSpc=0
if [ ! -x "$(command -v add-apt-repository)" ]; then
  apt-get install -y software-properties-common
  NeedSpc=1
fi


add-apt-repository -y ppa:damien-moore/codeblocks-stable
apt-get update
# Code::Blocks uses xterm to run console programs by default, let's not start depending on a specific terminal here
apt-get install -y codeblocks codeblocks-contrib xterm


if [ $NeedSpc -eq 1 ]; then
  apt-get purge --autoremove -y software-properties-common
fi
