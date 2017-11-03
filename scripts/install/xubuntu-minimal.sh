#!/bin/sh
# Install basic packages to run an xfce4 system from a remote desktop,
# providing users with a Xubuntu-like experience
# Note that "xubuntu-core" supposedly does this, but includes a ton of irrelevant packages
# We do not even include lightdm or xterm, because we don't need them for RDP

# Update packages, just in case
apt-get update
apt-get upgrade -y

# Apt installs too many packages by default, we only want the required ones
cat > '/etc/apt/apt.conf.d/99no-suggests-recommends' << EOF
APT::Install-Suggests "0";
APT::Install-Recommends "0";
EOF

# Apt will fail on the first error by default, which is annoying
cat > '/etc/apt/apt.conf.d/99retries' << EOF
Acquire::Retries "5";
EOF

# For some reason the default fstab contains an entry for floppy0, which we don't want
sed -i '/floppy0/d' '/etc/fstab'

# i2c_piix4 is a module that deals with the PIIX4 chip's System Management Bus (SMBus), but VMWare doesn't support it
# Not a huge deal, it just prints an error line on boot, but that's not very nice, we want no errors
echo '# Disabled since VMWare does not support it' >> '/etc/modprobe.d/blacklist.conf'
echo 'blacklist i2c_piix4' >> '/etc/modprobe.d/blacklist.conf'

# The default .bashrc for new users is slightly different than root's, which makes no sense.
cp '/root/.bashrc' '/etc/skel/.bashrc'

# xserver-xorg and xinit are the minimum required to have an X server
# open-vm-tools-desktop are required to run in a VMware virtual machine
# xfwm4 is the window manager, xfdesktop4 the desktop, xfce4-panel the panels, and xfce4-session the session
# libglib2.0-bin allows changing the themes and icons
# x11-xserver-utils and policykit-1 contain required thing for proper session login/logout
# The menu package automatically puts apps in the Applications menu
# Thunar is the XFCE file manager, xfce4-terminal is a terminal
# The themes are there to make it look decent
apt-get install -y xserver-xorg xinit \
                   open-vm-tools-desktop \
                   xfwm4 xfdesktop4 xfce4-panel xfce4-session \
                   libglib2.0-bin x11-xserver-utils policykit-1 \
                   menu \
                   thunar xfce4-terminal \
                   xubuntu-icon-theme greybird-gtk-theme

# Set the GTK theme, the default one makes Windows 95 look good
cat > '/usr/share/glib-2.0/schemas/99default-theme.gschema.override' << EOF
[org.gnome.desktop.interface]
gtk-theme='Greybird'
icon-theme='elementary-xfce'
EOF
glib-compile-schemas '/usr/share/glib-2.0/schemas/'
