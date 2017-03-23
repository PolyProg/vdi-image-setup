#!/bin/sh
# Installs development tools


### Installs Code::Blocks

add-apt-repository -y ppa:damien-moore/codeblocks-stable
apt update
apt install -y codeblocks codeblocks-contrib


### Installs Eclipse

# Install Java first
apt install -y openjdk-8-jdk

# Download and extract it
wget -O eclipse.tar.gz 'http://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/neon/2/eclipse-java-neon-2-linux-gtk-x86_64.tar.gz&r=1'
tar -zxvf eclipse.tar.gz -C /opt
rm eclipse.tar.gz

# Install the program
ln -s /opt/eclipse/eclipse /usr/local/bin

# Install the desktop shortcut
cat > /usr/share/applications/eclipse.desktop << EOF
[Desktop Entry]
Name=Eclipse
Type=Application
Exec=/opt/eclipse/eclipse
Terminal=false
Icon=/opt/eclipse/icon.xpm
Comment=Integrated Development Environment
NoDisplay=false
Categories=Development;IDE;
Name[en]=Eclipse
EOF

desktop-file-install /usr/share/applications/eclipse.desktop


### Installs Emacs

apt install -y emacs


### Installs Geany

apt install -y geany


## Installs Vim

apt install -y vim