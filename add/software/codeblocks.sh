#!/bin/sh
# Installs Code::Blocks

# Code::Blocks uses xterm to run console programs by default, let's not start depending on a specific terminal here
apt-get install -y codeblocks codeblocks-contrib xterm
