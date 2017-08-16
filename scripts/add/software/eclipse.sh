#!/bin/sh
# Installs Eclipse 4.8 "Photon"
# TODO can we autodetect the latest release?

### Install Java first
apt install -y openjdk-8-jdk


### Install the Eclipse Platform Runtime, i.e. the shell without any plugins whatsoever

# Download and extract platform
wget -O eclipse.tar.gz 'http://www.eclipse.org/downloads/download.php?file=/eclipse/downloads/drops4/S-4.8M1-201708022000/eclipse-platform-4.8M1-linux-gtk-x86_64.tar.gz&r=1'
tar -zxvf eclipse.tar.gz -C /opt
rm eclipse.tar.gz

# TODO see if we need to patch eclipse.ini for memory or other

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
Categories=Development;IDE;
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

cd /opt/eclipse

# Java development tools
install http://download.eclipse.org/releases/photon org.eclipse.jdt.feature.group

# C/C++ development tools
install http://download.eclipse.org/releases/photon org.eclipse.cdt.feature.group

# PyDev, a.k.a. Python for Eclipse
install http://www.pydev.org/updates org.python.pydev.feature.feature.group

# TODO scala maybe?
