#!/bin/sh
# Installs Code::Blocks

add-apt-repository -y ppa:damien-moore/codeblocks-stable
apt-get update
# Code::Blocks uses xterm to run console programs by default
# TODO figure out how to make it use the xfce terminal instead
apt-get install -y codeblocks codeblocks-contrib xterm
