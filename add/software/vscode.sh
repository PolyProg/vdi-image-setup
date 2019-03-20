#!/bin/sh
# Installs Visual Studio Code

wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > '/etc/apt/sources.list.d/vscode.list'

apt-get install -y apt-transport-https
apt-get update
# VS Code requires gvfs-bin to delete files, according to its 'Common questions' section
apt-get install -y code gvfs-bin
