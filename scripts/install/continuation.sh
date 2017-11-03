#!/bin/sh
# The rest of the install must be executed at the next boot

# We're going to parse XML, do it properly with xml_grep
apt-get install -y xml-twig-tools

# Single quotes around EOF mean the shell won't perform substitution in the file
cat > '/opt/install-continuation.sh' << 'EOF'
#!/bin/sh

# POSIX-compliant lowercasing and uppercasing (${x,,} and ${x^^} are bashisms)
lower() {
  echo $1 | tr '[A-Z]' '[a-z]'
}
upper() {
  echo $1 | tr '[a-z]' '[A-Z]'
}

# If there's no floppy, load the module
if [ ! -e '/dev/fd0' ]; then
  modprobe floppy
  sleep 2
  if [ ! -e '/dev/fd0' ]; then
    echo "Couldn't load the floppy module!" >&2
    exit
  fi
fi

# Create the destination floppy mount point
if [ ! -e '/media/floppy' ]; then
  mkdir -p '/media/floppy'
fi

# Mount the floppy
mount -t msdos -w '/dev/fd0' '/media/floppy'
if [ $? -ne 0 ] ; then
  echo "Floppy drive not found. Error: $?" >&2
  exit
fi

# Ensure unattend.xml exists
if [ ! -f '/media/floppy/unattend.xml' ]; then
  echo "No unattend.xml file found." >&2
  umount '/media/floppy'
  exit
fi

# Find the (only) network interface
NetworkInterface="$(ls /sys/class/net | grep -v lo)"

# Extract values from environment and unattend.xml
getxmlval() {
  xml_grep "$1" '/media/floppy/unattend.xml' --text_only
}
ComputerName="$(getxmlval 'ComputerName')"
FQDN="$(getxmlval 'JoinDomain')"
DN="$(getxmlval 'Domain')"
UserName="$(getxmlval 'Username')"
Password="$(getxmlval 'Credentials/Password')" # there are 2 <Password> elements, we want AD credentials, not Administrator user
OU="$(getxmlval 'MachineObjectOU')"
CommandLine="$(getxmlval 'CommandLine')"
vWGUID="$(echo $CommandLine | tr -s ' ' | cut -d ' ' -f4 | cut -d '=' -f2)"
vWBroker="$(echo $CommandLine | tr -s ' ' | cut -d ' ' -f5 | cut -d '=' -f2)"
MAC="$(ifconfig | grep $NetworkInterface | awk '{ print $5 }')"
OSInfo="$(uname -srm)"

# Set the IP address and subnet, waiting a bit if needed for the IP to be obtained
setip() {
  IP="$(ifconfig $NetworkInterface | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')"

  if [ ! -z "$IP" ] && [ "$IP" != '127.0.0.1' ]; then
    Subnet="$(ifconfig $NetworkInterface | sed -rn ''2's/ .*:(.*)$/\1/p')"
  else
    sleep 2
    setip
  fi
}
setip

# Get all AD servers by checking the DNS records, then join them in a single line for configs
IFS='
'
ADServers="$(dig +short _ldap._tcp.$(lower $FQDN) SRV | awk '{ print $4 }' | sed -e 's/\.*$//')"
JoinedADServers=''
for Server in $ADServers; do
  JoinedADServers="$JoinedADServers $Server"
done

# Fill in placeholders in the QDCSVC conf
sed -i "s/##fqdndom##/$(lower $FQDN)/" '/etc/qdcsvc.conf'
sed -i "s/##VWGUID##/$vWGUID/" '/etc/qdcsvc.conf'
sed -i "s/##COMPNAME##/$(lower $ComputerName)/" '/etc/qdcsvc.conf'
sed -i "s/##IPADDR##/$IP/" '/etc/qdcsvc.conf'
sed -i "s/##SUBNET##/$Subnet/" '/etc/qdcsvc.conf'
sed -i "s/##MACADDR##/$MAC/" '/etc/qdcsvc.conf'
sed -i "s/##OSINFO##/$OSInfo/" '/etc/qdcsvc.conf'
sed -i "s/##BROKER##/$(lower $vWBroker)/" '/etc/qdcsvc.conf'
sed -i "s/##OU##/CN=$(lower $ComputerName),$OU/" '/etc/qdcsvc.conf'

# Fill in placeholders in the Kerberos conf (including the KDC and Main servers)
sed -i "s/##FQDNDOM##/$(upper $FQDN)/" '/etc/krb5.conf'
sed -i "s/##fqdndom##/$(lower $FQDN)/" '/etc/krb5.conf'
for Server in $ADServers; do
  sed -i "/##KDCSERVER##/a\\
   kdc = $(lower $Server)
" '/etc/krb5.conf'
done
sed -i "/##ADMINSERVER##/a\\
   admin_server = $(lower $JoinedADServers)
" '/etc/krb5.conf'

# Fill in placeholders in the Samba conf
sed -i "s/##NETDOM##/$(upper $DN)/" '/etc/samba/smb.conf'
sed -i "s/##fqdndom##/$(lower $FQDN)/" '/etc/samba/smb.conf'

# Fill in placeholders in the sssd conf
sed -i "s/##FQDNDOM##/$(upper $FQDN)/" '/etc/sssd/sssd.conf'

# TODO this is epfl-specific
# Add AD servers to hosts, otherwise lookup fails at EPFL
echo '# Kerberos servers' >> '/etc/hosts'
for Server in $ADServers; do
  ServerIp="$(nslookup $(lower $Server) | sed -n '5p' | cut -d ' ' -f2)"
  echo "$ServerIp $(lower $Server)" >> '/etc/hosts'
done

# Rename host
hostnamectl set-hostname --static "$ComputerName.$FQDN"

# Enable NTP
echo "NTP=$JoinedADServers" >> '/etc/systemd/timesyncd.conf'
timedatectl set-ntp true

# Fix a Samba problem with DNS not being found (see https://wiki.samba.org/index.php/Troubleshooting_Samba_Domain_Members)
echo '# Workaround for a Samba issue' >> '/etc/hosts'
echo "$IP $ComputerName.$FQDN $ComputerName" >> '/etc/hosts'

# Start Samba. For some reason enable --now doesn't work, perhaps because they are really sysvinit scripts
systemctl enable smbd nmbd
systemctl start smbd nmbd

# Get a Kerberos ticket (-s = read password from stdin)
echo "$Password" | k5start -s "$UserName"

# Join the domain
# Sometimes it fails for no reason
JOIN_RETRIES=10
for join_retry in $(seq 1 $JOIN_RETRIES); do
  net ads join -U "$UserName"%"$Password" && break

  if [ join_retry -eq $JOIN_RETRIES ]; then
    # All hope is lost :(
    echo 'Could not join AD.' > /var/log/ad_error.log
    sync
    shutdown -h now
  else
    sleep 10
  fi
done

net ads dns register -U "$UserName"%"$Password"

# Start SSSD
systemctl enable --now sssd

# Remove all files from the floppy (unattend.xml contains plaintext credentials!)
rm -f '/media/floppy/*'

# Unmount the floppy
umount '/media/floppy'

# Disable this service (see below, outside continuation, for the installation)
systemctl disable install-continuation.service
EOF

# Make the continuation root-only
chmod 700 '/opt/install-continuation.sh'

# Install the continuation as a system service
cat > '/etc/systemd/system/install-continuation.service' << EOF
[Unit]
Description = Install continuation
Requires = network-online.target krenew.service qdcsvc.service
Before = krenew.service qdcsvc.service
After = network-online.target

[Service]
Type=oneshot
ExecStart=/opt/install-continuation.sh

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (it will disable itself after its first run, see above)
systemctl daemon-reload
systemctl enable install-continuation.service
