#!/bin/sh
# Installs Visual Studio Code

wget -O - 'https://packages.microsoft.com/keys/microsoft.asc' | gpg --dearmor > 'microsoft.gpg'
install -o root -g root -m 644 'microsoft.gpg' '/etc/apt/trusted.gpg.d/'
rm 'microsoft.gpg'
echo 'deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main' > '/etc/apt/sources.list.d/vscode.list'

apt-get install -y apt-transport-https
apt-get update
# VS Code requires gvfs-bin to delete files, according to its 'Common questions' section
apt-get install -y code gvfs-bin

# Java support & debugger
if [ -x "$(command -v javac)" ]; then
  code --install-extension 'redhat.java'
  code --install-extension 'vscjava.vscode-java-debug'
fi

# C and C++ support
if [ -x "$(command -v gcc)" ]; then
  code --install-extension 'ms-vscode.cpptools'
fi

# Python support
if [ -x "$(command -v python)" ] || [ -x "$(command -v python3)" ]; then
  code --install-extension 'ms-python.python'
fi

# Scala support
if [ -x "$(command -v scalac)" ]; then
  code --install-extension 'scala-lang.scala'
fi
