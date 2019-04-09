#!/bin/sh
# Installs Eclipse 4.10

# Install desktop-file-utils for desktop-file-install
NeedDfu=0
if [ ! -x "$(command -v desktop-file-install)" ]; then
  apt-get install -y desktop-file-utils
  NeedDfu=1
fi

# Install Java first, if needed
if [ ! -x "$(command -v java)" ]; then
  apt-get install -y openjdk-11-jre
fi

# Download and extract the Eclipse Platform, i.e. the shell without any plugins whatsoever
# NOTE: The url is sometimes brittle... hard to tell when they drop old versions
wget -O 'eclipse.tar.gz' 'http://ftp.halifax.rwth-aachen.de/eclipse//eclipse/downloads/drops4/R-4.11-201903070500/eclipse-platform-4.11-linux-gtk-x86_64.tar.gz'
tar -xf 'eclipse.tar.gz' -C '/opt'
rm 'eclipse.tar.gz'

# Install it
ln -s '/opt/eclipse/eclipse' '/usr/local/bin'

# Create a desktop shortcut
cat > '/usr/share/applications/eclipse.desktop' << EOF
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
desktop-file-install '/usr/share/applications/eclipse.desktop'


### Add tools

addIU() {
  eclipse -nosplash -application org.eclipse.equinox.p2.director \
          -repository $1 \
          -installIU $2 \
          -destination '/opt/eclipse'
}

# Java
if [ -x "$(command -v javac)" ]; then
  addIU 'http://download.eclipse.org/releases/2019-03' 'org.eclipse.jdt.feature.group'
fi

# C/C++
if [ -x "$(command -v gcc)" ]; then
  # Eclipse uses make to compile
  apt-get install -y make
  addIU 'http://download.eclipse.org/releases/2019-03' 'org.eclipse.cdt.feature.group'
fi

# PyDev
if [ -x "$(command -v python)" ] || [ -x "$(command -v python3)" ]; then
  addIU 'http://www.pydev.org/updates' 'org.python.pydev.feature.feature.group'
fi

# Scala IDE
if [ -x "$(command -v scalac)" ]; then
  addIU 'http://downloads.typesafe.com/scalaide/sdk/lithium/e47/scala212/stable/site' 'org.scala-ide.sdt.feature.feature.group'
fi


if [ $NeedDfu -eq 1 ]; then
  apt-get purge --autoremove -y desktop-file-utils
fi
