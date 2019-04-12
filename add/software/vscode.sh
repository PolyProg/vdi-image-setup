#!/bin/sh
# Installs Visual Studio Code

apt-get install -y gnupg
wget -O - 'https://packages.microsoft.com/keys/microsoft.asc' | gpg --dearmor > 'microsoft.gpg'
install -o root -g root -m 644 'microsoft.gpg' '/etc/apt/trusted.gpg.d/'
rm 'microsoft.gpg'
echo 'deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main' > '/etc/apt/sources.list.d/vscode.list'

# Note that Bionic doesn't need apt-transport-https any more
apt-get update
# VS Code requires gvfs-bin to delete files, according to its 'Common questions' section
apt-get install -y code gvfs-bin

# VS Code doesn't want to put user data in /root, so we need a special dir
# But we don't actually use user data, so we can delete it later
mkdir '/tmp/vscode-user'
chmod 777 '/tmp/vscode-user'

addtocode() {
  code '--user-data-dir=/tmp/vscode-user' --install-extension "$1"
}

# Java support & debugger
if [ -x "$(command -v javac)" ]; then
  addtocode 'redhat.java'
  addtocode 'vscjava.vscode-java-debug'
fi

# No C/C++, the extension needs to install dependencies when first run, out of the question in our scenario

# Python support
if [ -x "$(command -v python)" ] || [ -x "$(command -v python3)" ]; then
  addtocode 'ms-python.python'
fi

# Scala support
if [ -x "$(command -v scalac)" ]; then
  addtocode 'scala-lang.scala'
fi

rm -rf '/tmp/vscode-user'

# Install the extensions for all users
cp -r '/root/.vscode' '/etc/skel/.vscode'
