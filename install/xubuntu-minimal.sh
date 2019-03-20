#!/bin/sh
# Install basic packages to run an xfce4 system,
# providing users with a Xubuntu-like experience
# Note that "xubuntu-core" supposedly does this, but includes a ton of irrelevant packages

# Apt installs too many packages by default, we only want the required ones
# Also, autoremove by default doesn't remove suggested/recommended packages
cat > '/etc/apt/apt.conf.d/99no-suggests-recommends' << EOF
APT::Install-Suggests "false";
APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
EOF

# Apt will fail on the first error by default, which is annoying
cat > '/etc/apt/apt.conf.d/99retries' << EOF
Acquire::Retries "5";
EOF

# Update packages
apt-get update
apt-get upgrade -y
apt-get autoremove -y

# i2c_piix4 is a module that deals with the PIIX4 chip's System Management Bus (SMBus), but VMWare doesn't support it
# Not a huge deal, it just prints an error line on boot, but that's not very nice, we want no errors
echo '# Disabled since VMWare does not support it' >> '/etc/modprobe.d/blacklist.conf'
echo 'blacklist i2c_piix4' >> '/etc/modprobe.d/blacklist.conf'

# The default .bashrc for new users is slightly different than root's, which makes no sense.
cp '/root/.bashrc' '/etc/skel/.bashrc'

# xserver-xorg and xinit are the minimum required to have an X server
# xfwm4 is the window manager, xfdesktop4 the desktop, xfce4-panel the panels, and xfce4-session the session
# libglib2.0-bin allows changing the themes and icons
# x11-xserver-utils and policykit-1 contain required things for proper session login/logout
# LightDM is the display manager, and requires a greeter to go along with it (Unity because VMware Horizon needs it)
# The menu package automatically puts apps in the Applications menu
# Thunar is the XFCE file manager, xfce4-terminal is a terminal
# The themes are there to make it look decent
apt-get install -y xserver-xorg xinit \
                   xfwm4 xfdesktop4 xfce4-panel xfce4-session \
                   libglib2.0-bin x11-xserver-utils policykit-1 \
                   lightdm unity-greeter \
                   menu \
                   thunar xfce4-terminal \
                   xubuntu-icon-theme greybird-gtk-theme

# Tell LightDM to use XFCE, otherwise it fails to start the session
printf '[Seat:*]\nuser-session=xfce\n' > /etc/lightdm/lightdm.conf.d/99xfce.conf

# Disable guest option in LightDM, just in case (from https://askubuntu.com/a/169105/642930)
printf '[Seat:*]\nallow-guest=false\n' > /etc/lightdm/lightdm.conf.d/99no-guest.conf

# Remove KWallet and GNOME Keyring integration that LightDM adds to PAM (we don't have either, they cause errors)
sed -i '/kwallet\|gnome_keyring/d' '/etc/pam.d/lightdm'

# Set the GTK theme, the default one makes Windows 95 look good
cat > '/usr/share/glib-2.0/schemas/99default-theme.gschema.override' << EOF
[org.gnome.desktop.interface]
gtk-theme='Greybird'
icon-theme='elementary-xfce'
EOF
glib-compile-schemas '/usr/share/glib-2.0/schemas/'
