#!/bin/sh
# Installs Eclipse 4.8 "Photon"

# Install Java first
apt-get install -y openjdk-8-jre

# Download and extract the Eclipse Platform, i.e. the shell without any plugins whatsoever
wget -O eclipse.tar.gz 'http://www.eclipse.org/downloads/download.php?file=/eclipse/downloads/drops4/S-4.8M3a-201710300400/eclipse-platform-4.8M3a-linux-gtk-x86_64.tar.gz&r=1'
tar -zxvf eclipse.tar.gz -C /opt
rm eclipse.tar.gz

# Install it
ln -s /opt/eclipse/eclipse /usr/local/bin

# Create a desktop shortcut
cat > /usr/share/applications/eclipse.desktop << EOF
[Desktop Entry]
Name=Eclipse
Type=Application
Exec=/opt/eclipse/eclipse
Terminal=false
Icon=/opt/eclipse/icon.xpm
Comment=Integrated Development Environment
NoDisplay=false
Categories=Development;
Name[en]=Eclipse
EOF

# Install the shortcut
desktop-file-install /usr/share/applications/eclipse.desktop


### Add tools

install() {
  eclipse -nosplash -application org.eclipse.equinox.p2.director \
          -repository $1 \
          -installIU $2
}

# Java
if [ -x "$(command -v javac)" ]; then
  install http://download.eclipse.org/releases/photon org.eclipse.jdt.feature.group
fi

# C/C++
if [ -x "$(command -v gcc)" ]; then
  # Eclipse uses make to compile
  apt-get install -y make
  install http://download.eclipse.org/releases/photon org.eclipse.cdt.feature.group
fi

# PyDev
if [ -x "$(command -v python)" ] || [ -x "$(command -v python3)" ]; then
  install http://www.pydev.org/updates org.python.pydev.feature.feature.group
fi

# Scala IDE
if [ -x "$(command -v scalac)" ]; then
  install http://downloads.typesafe.com/scalaide/sdk/lithium/e47/scala212/stable/site org.scala-ide.sdt.feature.feature.group
fi
