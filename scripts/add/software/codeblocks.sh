#!/bin/sh
# Installs Code::Blocks

add-apt-repository -y ppa:damien-moore/codeblocks-stable
apt update
# Code::Blocks uses xterm to run console programs by default
# TODO figure out how to make it use the xfce terminal instead
apt install -y codeblocks codeblocks-contrib xterm
