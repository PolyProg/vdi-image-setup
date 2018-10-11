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
# Others are options; disable everything except the managed client (recommended, -M)
# Do not explicitly disable FIPS (-f), it's not even supported on Ubuntu
cd horizon-client
./install_viewagent.sh -A yes \
                       -a no \
                       -m no \
                       -r no \
                       -C no \
                       -F no \
                       -S no \
                       -U no \
                       -M yes

# Remove the tar and the folder, not needed any more
cd ..
rm -f horizon-client.tar.gz
rm -rf horizon-client

# Patch the config (EOF between quotes to not have to escape backslashes)
cat > /etc/vmware/viewagent-custom.conf << 'EOF'
# We're not using PBISO
echo 'OfflineJoinDomain=none'
# Use the AD join script
echo 'RunOnceScript=/opt/ad-join.sh'
# Use usernames with domains
echo 'SSOUserFormat=[domain]\\[username]'
EOF

# TODO consider purging some of the deps like Zenity, it even includes emacs common files...

# Restore the working directory
cd "$WorkDir"
