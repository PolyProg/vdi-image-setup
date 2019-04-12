#!/bin/sh
# Installs NetBeans

# Install unzip
NeedUz=0
if [ ! -x "$(command -v unzip)" ]; then
  apt-get install -y unzip
  NeedUz=1
fi

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

# Download and extract it
wget -O 'netbeans.zip' 'http://mirror.easyname.ch/apache/incubator/netbeans/incubating-netbeans/incubating-11.0/incubating-netbeans-11.0-bin.zip'
unzip 'netbeans.zip' -d '/opt'
rm 'netbeans.zip'

# Install it
ln -s '/opt/netbeans/bin/netbeans' '/usr/local/bin'

# Create a desktop shortcut
cat > '/usr/share/applications/netbeans.desktop' << EOF
[Desktop Entry]
Name=NetBeans
Type=Application
Exec=/opt/netbeans/bin/netbeans
Terminal=false
Comment=Integrated Development Environment
NoDisplay=false
Categories=Development;
Name[en]=NetBeans
EOF

# Install the shortcut
desktop-file-install '/usr/share/applications/netbeans.desktop'

if [ $NeedUz -eq 1 ]; then
  apt-get purge --autoremove -y unzip
fi

if [ $NeedDfu -eq 1 ]; then
  apt-get purge --autoremove -y desktop-file-utils
fi
