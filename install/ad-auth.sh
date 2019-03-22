#!/bin/sh
# Configures the machine to join Active Directory; leaves behind a single-use /opt/ad-join.sh to redo the join.
# Parameters:
# $1: The user
# $2: The password
# $3: The domain
# $4: The OU of the computers in AD


# Install the packages:
# - sssd and dependencies (by default only recommended...)
# - realmd and dependencies
#   note that without policykit-1, realm doesn't work as root, see https://bugs.freedesktop.org/show_bug.cgi?id=90683
# NOTE: sssd-tools requires python2 while everything else is happy with 3, unfortunately
apt-get install -y sssd libnss-sss libpam-sss libsss-sudo libsasl2-modules-gssapi-mit \
                   realmd policykit-1 adcli sssd-tools

# Add pam_mkhomedir to create home dirs properly
# umask=0077 means only users can access their homedir, nobody else
sed -i '/pam_sss.so/a session optional\tpam_mkhomedir.so umask=0077' '/etc/pam.d/common-session'

# Create the AD-join script
cat > /opt/ad-join.sh << EOF
#!/bin/sh

# --install=/ so that realm doesn't try to install stuff (which would fail since we did not install packagekit)
echo "$2" | realm join --install=/ --computer-ou="$4" --user="$1"@"$3" "$3"
EOF

# Make the script executable and root-only
chmod 700 /opt/ad-join.sh

# Run the script now to join once
/opt/ad-join.sh

# Make the script self-destruct the next time it's run, since it contains a password
echo 'rm -f /opt/ad-join.sh' >> /opt/ad-join.sh
