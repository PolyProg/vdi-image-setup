#!/bin/sh
# Install Samba & co, for Active Directory auth

# Install the packages:
# - kstart contains k5start, an enhanced kinit, and krenew, to renew tickets automatically
# - samba and a required module (that is by default only recommended)
# - sssd and a few required libs (again, only recommended by default)
apt-get install -y kstart \
                   samba-common-bin samba-dsdb-modules \
                   sssd libnss-sss libpam-sss libsss-sudo libsasl2-modules-gssapi-mit

# Disable sssd for now, it'll be enabled on startup once the configs' placeholders are filled
systemctl disable sssd

# Add pam_mkhomedir to create home dirs properly
# umask=0077 means only users can access their homedir, nobody else
sed -i '/pam_sss.so/a session optional\tpam_mkhomedir.so umask=0077' '/etc/pam.d/common-session'

# Create a config file for sssd, with placeholders
cat > '/etc/sssd/sssd.conf' << EOF
[sssd]
config_file_version = 2
services = nss, pam
domains = ##FQDNDOM##

[domain/##FQDNDOM##]
# LDAP for identity, but no access control (vWorkspace performs it)
id_provider = ldap
access_provider = permit

# Use the existing AD connection to bind to LDAP
ldap_sasl_mech = GSSAPI
ldap_sasl_canonicalize = true

# Set the proper home directory
override_homedir = /home/%u

# TODO move those to epfl-specific!
# Set user and group classes (defaults are POSIX-related stuff)
ldap_user_object_class = user
ldap_group_object_class = group

# Disable TLS (I can't make it work! TODO make it work)
ldap_tls_reqcert = never
EOF

# Put proper permissions on sssd's config, otherwise it refuses to start (https://help.ubuntu.com/lts/serverguide/sssd-ad.html)
chown root:root '/etc/sssd/sssd.conf'
chmod 600 '/etc/sssd/sssd.conf'

# Create a config file for Samba, with placeholders
cat > '/etc/samba/smb.conf' << EOF
[global]
# Public comment about the machine
server string = vWorkspace Provisioned Linux Host
# Workgroup
workgroup = ##NETDOM##
# Kerberos realm
realm = ##fqdndom##
# Allow joining a Windows domain
security = ads
# Use a keytab for Kerberos
kerberos method = secrets and keytab
# Don't participate in local master elections
local master = no
# Don't force a master election (the doc says the default is 'auto', without explaining what that means)
preferred master = no
# Disable printers (from https://lists.samba.org/archive/samba/2006-January/116969.html)
load printers = no
disable spoolss = yes
printing = bsd
printcap name = /dev/null
EOF

# Install the config file for Kerberos (with placeholders)
cp '/opt/VDEFORLINUX/Provisioning/krb5.conf' '/etc/krb5.conf'

# Disable NTP (will be re-enabled by the ad-config script)
timedatectl set-ntp false

# Add a service to auto-renew the Kerberos ticket
# krenew args -K <n> = Wake up every n minutes to check if the ticket needs renewal
cat > '/etc/systemd/system/krenew.service' << EOF
[Unit]
Description = Kerberos ticket auto-renewal
Requires = network-online.target
After = network-online.target

[Service]
ExecStart=/usr/bin/krenew -K 60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable krenew.service
