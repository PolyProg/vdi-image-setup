#!/bin/sh
# Installs VMware's Horizon Client, assuming a compressed version of it exists at /opt/horizon-client.tar.gz
# and that a script /opt/ad-join.sh exists to join the AD

# Save the working directory to restore it later
WorkDir=$(pwd)

# Install the dependencies:
# - First line contains those that are officially declared
# - Second line contains those that are not...
# - xserver-xorg-video-vmware is required to properly handle non-800x600 displays
apt-get install -y open-vm-tools-desktop python python-dbus python-gobject \
                   zenity pulseaudio-utils xinput \
                   xserver-xorg-video-vmware

# Untar the client, in a folder we know
cd /opt
mkdir horizon-client
tar xf horizon-client.tar.gz -C horizon-client --strip-components=1

# Install the client
# -A yes is for accepting the EULA
# Others are options; disable everything except the managed client (recommended, -M) and Single-Sign ON (a.k.a. SSO, -S)
# Do not explicitly disable FIPS (-f), it's not even supported on Ubuntu
cd horizon-client
./install_viewagent.sh -A yes \
                       -a no \
                       -m no \
                       -r no \
                       -C no \
                       -F no \
                       -M yes \
                       -S yes \
                       -U no

# Remove the tar and the folder, not needed any more
cd ..
rm -f horizon-client.tar.gz
rm -rf horizon-client

# Patch the config (EOF between quotes to not have to escape backslashes)
cat >> /etc/vmware/viewagent-custom.conf << 'EOF'
# We're not using PBISO
OfflineJoinDomain=none
# Use the AD join script
RunOnceScript=/opt/ad-join.sh
# Use usernames with domains
SSOUserFormat=[domain]\\[username]
EOF

# Patch the SSSD config to make it case-insensitive, as requested by VMware Horizon
sed -i '/\[domain/a case_sensitive = false' /etc/sssd/sssd.conf

# VMWare Horizon expects a MAC address for DHCP, not the new Ubuntu 18 default of RFC4361-compliant IDs
sed -i '/dhcp4/a\ \ \ \ \ \ dhcp-identifier: mac' '/etc/netplan/'*

# Restore the working directory
cd "$WorkDir"
