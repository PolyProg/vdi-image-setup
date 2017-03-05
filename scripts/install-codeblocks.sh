#!/bin/sh

### Installs Code::Blocks (latest version)

add-apt-repository ppa:damien-moore/codeblocks-stable
apt update
apt install -y codeblocks codeblocks-contrib