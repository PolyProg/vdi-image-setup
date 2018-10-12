#!/bin/sh
# Installs VMware's Horizon Client, assuming a compressed version of it exists at /opt/horizon-client.tar.gz
# and that a script /opt/ad-join.sh exists to join the AD

# Save the working directory to restore it later
WorkDir=$(pwd)

# Install the dependencies:
# - First line contains those that are officially declared
# - Second line contains those that are not...
apt-get install -y open-vm-tools-desktop python-dbus python-gobject \
                   zenity pulseaudio-utils xinput

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
                       -U no \
                       -S yes \
                       -M yes

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


### Set the default keyboard to match the keyboard of the VMware Horizon View client on login

cat > '/opt/keyboard.sh' << 'EOF'
#!/bin/sh

# sleep is required for it to work... for some reason.
sleep 2
setxkbmap $(cat /var/log/vmware/keyboardLayout)
EOF

chmod 755 '/opt/keyboard.sh'

mkdir -p '/etc/skel/.config/autostart'
cat > '/etc/skel/.config/autostart/Keyboard.desktop' << EOF
[Desktop Entry]
Version=1.0
Name=Script
Type=Application
Exec=/opt/keyboard.sh
Terminal=false
StartupNotify=false
Hidden=false
EOF

chmod 755 '/etc/skel/.config/autostart/Keyboard.desktop'

# Make it work for root as well
mkdir -p '/root/.config/autostart'
cp '/etc/skel/.config/autostart/Keyboard.desktop' '/root/.config/autostart/Keyboard.desktop'


# Restore the working directory
cd "$WorkDir"
