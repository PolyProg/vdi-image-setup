#!/bin/sh
# Installs Code::Blocks

add-apt-repository -y ppa:damien-moore/codeblocks-stable
apt update
apt install -y codeblocks codeblocks-contrib
