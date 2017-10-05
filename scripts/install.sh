#!/bin/sh
# Installs the necessary tools to run Xubuntu Core 16.04 on Dell vWorkspace
# Must be run on an Ubuntu Mini 16.04 x64 image,
# Written by Solal Pirelli
# Original vWorkspace scripts written by Stephen Yorke (Dell)

### Check for prerequisites
### First the platform, then the stuff that can be changed

if [ ! -e '/usr/bin/lsb_release' ]; then
  echo 'Please run this script under Ubuntu' >&2
  exit 1
fi

case "$(lsb_release -d)" in
  *'Ubuntu 16.04'*)
    :
    ;;
  *)
    echo 'Please run this script under Ubuntu 16.04' >&2
    exit 2
    ;;
esac

if [ "$(uname -i)" != 'x86_64' ]; then
  echo 'Please run this script on an x64 OS' >&2
  exit 3
fi

NetworkInterface="$(ls /sys/class/net | grep -v lo)"
if [ "$(echo $NetworkInterface | wc -l)" -ne '1' ]; then
  echo 'Please run this script in a machine with only 1 interface (apart from loopback)' >&2
  exit 4
fi

if [ "$(id -u)" != '0' ]; then
  echo 'Please run this script as root' >&2
  exit 5
fi

if [ ! -d '/opt/VDEFORLINUX' ]; then
  echo 'Please put the vWorkspace VDEFORLINUX folder in /opt/VDEFORLINUX' >&2
  exit 6
fi


### Update dependencies, just in case

apt update
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y --purge


### Work around Ubuntu bugs/annoyances

# Apt installs too many packages by default, we only want the required ones
cat > '/etc/apt/apt.conf.d/99no-suggests-recommends' << EOF
APT::Install-Suggests "0";
APT::Install-Recommends "0";
EOF

# Apt will fail on the first error by default, which is annoying
cat > '/etc/apt/apt.conf.d/99retries' << EOF
Acquire::Retries "5";
EOF

# For some reason the default fstab contains an entry for floppy0, but it doesn't work in our case
sed -i '/floppy0/d' '/etc/fstab'

# i2c_piix4 is a module that deals with the PIIX4 chip's System Management Bus (SMBus), but VMWare doesn't support it
# Not a huge deal, it just prints an error line on boot, but that's not very nice, we want no errors
echo '# Disabled since VMWare does not support it' >> '/etc/modprobe.d/blacklist.conf'
echo 'blacklist i2c_piix4' >> '/etc/modprobe.d/blacklist.conf'

# The default .bashrc for new users is slightly different than root's, which makes no sense.
cp '/root/.bashrc' '/etc/skel/.bashrc'


### Install basic packages to run an xfce4 system from a remote desktop
### Note that "xubuntu-core" supposedly does this, but includes a ton of irrelevant packages
### We do not even include lightdm or xterm, because we don't need them for RDP

# Install libglib2.0 utilities first so that glib schemas can be installed
apt install -y libglib2.0-bin

# The menu package automatically puts apps in the Applications menu
# Thunar is the XFCE file manager, xfce4-terminal is... a terminal
# The themes are there to make it look decent
apt install -y xserver-xorg xinit \
               xfwm4 xfdesktop4 xfce4-panel xfce4-session \
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


### Install git, since some of the software this script installs is git-cloned

apt install -y git


### Install VMware tools

apt install -y open-vm-tools-desktop


### Install Samba & co, for Active Directory auth

# Install the packages:
# - kstart contains k5start, an enhanced kinit, and krenew, to renew tickets automatically
# - samba and a required module (that is by default only recommended)
# - sssd and a few required libs (again, only recommended by default)
apt install -y kstart \
               samba samba-dsdb-modules \
               sssd libnss-sss libpam-sss libsss-sudo libsasl2-modules-gssapi-mit

# Disable them for now, they'll be enabled on startup once their configs' placeholders are filled
systemctl disable smbd nmbd sssd

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


### Install xrdp

# Dependencies, as per their READMEs
# xrdp
apt install -y gcc make \
               autoconf automake libtool pkgconf \
               libssl-dev libpam0g-dev \
               libx11-dev libxfixes-dev libxrandr-dev
# xorgxrdp
apt install -y nasm xserver-xorg-dev


# xrdp
cd '/opt'
git clone --recursive https://github.com/neutrinolabs/xrdp
cd 'xrdp'

# Patch xrdp, as for some weird reason vWorkspace doesn't work otherwise
NUMLOGONNORMAL=$(grep -n "RDP_LOGON_NORMAL" common/xrdp_constants.h | cut -d ":" -f1)
sed -i ''${NUMLOGONNORMAL}'s/0x0033/0x0013/' common/xrdp_constants.h

# Install xrdp normally - it's recommended to install it before xorgxrdp
./bootstrap
./configure
make
make install

# Install xorgxrdp, a.k.a. reusing the existing Xorg with xrdp
cd '/opt'
git clone https://github.com/neutrinolabs/xorgxrdp
cd 'xorgxrdp'
./bootstrap
./configure
make
make install

# For some reason xrdp stuff is in /usr/local/sbin but expected to be in /usr/sbin
ln -s '/usr/local/sbin/xrdp' '/usr/sbin/xrdp'
ln -s '/usr/local/sbin/xrdp-chansrv' '/usr/sbin/xrdp-chansrv'
ln -s '/usr/local/sbin/xrdp-sesman' '/usr/sbin/xrdp-sesman'
ln -s '/usr/local/sbin/xrdp-sessvc' '/usr/sbin/xrdp-sessvc'

# We really want XRDP (and its session manager) to be restarted if it dies
sed -i '/\[Service\]/a Restart=always' '/lib/systemd/system/xrdp.service'
sed -i '/\[Service\]/a Restart=always' '/lib/systemd/system/xrdp-sesman.service'

# Apply the changes, and enable XRDP
systemctl daemon-reload
systemctl enable xrdp.service
systemctl enable xrdp-sesman.service

# The xrdp.sh script is an old thing that shouldn't be used any more; replace it with a systemd shim
# Otherwise, `xrdp.sh restart` hangs because it waits for xrdp to stop but we made it `Restart=always` above
cat > '/etc/xrdp/xrdp.sh' << EOF
# This script has been replaced by a systemd wrapper
systemctl \$1 xrdp
EOF

# Set the proper config
cat > '/etc/xrdp/xrdp.ini' << EOF
[Globals]
ini_version=1

port=3389

tcp_nodelay=true
tcp_keepalive=true

; vWorkspace requires that this be set to negotiate
security_layer=negotiate
crypt_level=high
ssl_protocols=TLSv1, TLSv1.1, TLSv1.2

allow_channels=true
allow_multimon=true
bitmap_cache=true
bitmap_compression=true
bulk_compression=true
max_bpp=32
use_fastpath=both
new_cursors=true

autorun=Xorg


; Sound (rdpsnd) is disabled, it causes problems (TODO fix that)
[Channels]
rdpdr=true
rdpsnd=false
drdynvc=true
cliprdr=true
rail=true
xrdpvr=true
tcutils=true

[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20
EOF


### Build FreeRDP/FreeRDS from the vWorkspace repo, since QDCSVC, the Quest Data Collector Service
### which is used by vWorkspace, depends on that specific version of libwinpr, as well as on two freerds libs
### This is inspired from the FreeRDS scripts, but without the parts we don't need

# Apparently this is required by FreeRDS (?)
export LD_LIBRARY_PATH=/usr/lib

# Required to build
apt install -y build-essential cmake

# Clone FreeRDP, then FreeRDS as a subfolder (yes, that's normal)
cd '/opt'
git clone https://github.com/vworkspace/FreeRDP.git --branch awakecoding --single-branch
cd 'FreeRDP/server'
git clone https://github.com/vworkspace/FreeRDS.git --branch awakecoding --single-branch

# Remove the FreeRDS Greeter, which depends on QT for... a timer.
# Otherwise it requires pulling all of QT just for a greeter we don't even use.
rm -rf FreeRDS/widgets
sed -i 's/add_subdirectory(widgets)//g' FreeRDS/CMakeLists.txt

# Not in the official dependencies list, but required anyway
apt install -y libcap-dev libssl-dev libltdl-dev

# Build FreeRDS first, since it's a sub-thing
apt install -y bison flex intltool \
               libboost-dev libexpat1-dev libfontconfig1-dev libfreetype6-dev libfuse-dev libgl1-mesa-dev libjpeg-dev libjson-c-dev libpam0g-dev \
               libpciaccess-dev libpixman-1-dev libpng12-dev libtool libsndfile1-dev libxml-libxml-perl \
               mesa-common-dev \
               x11proto-gl-dev xorg-dev xsltproc xutils-dev
cd '/opt/FreeRDP/server/FreeRDS/module/X11/service/xorg-build'
cmake .
make
cd ..
# magic, comes from the FreeRDS install docs (https://github.com/awakecoding/FreeRDP-Manuals/blob/master/Developer/FreeRDP-Developer-Manual.markdown)
ln -s 'xorg-build/external/Source/xorg-server' .

# Install FreeRDP dependencies
apt install -y libasound2-dev libavcodec-dev libavutil-dev libcups2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libpulse-dev \
               libssl-dev libx11-dev libxcursor-dev libxdamage-dev libxext-dev libxi-dev libxinerama-dev libxkbfile-dev libxrandr-dev libxrender-dev libxv-dev

# Generate all FreeRDP files (necessary now since we're fixing compilation errors later, some of which are in generated files)
cd '/opt/FreeRDP'
cmake -DWITH_SERVER=on -DWITH_XRDS=on .

# Fix compilation error, a parameter in an Xorg function was removed (https://lists.x.org/archives/xorg-devel/2014-December/044896.html)
sed -i 's/GetKeyboardEvents(pEventList, g_keyboard, type, scancode, NULL)/GetKeyboardEvents(pEventList, g_keyboard, type, scancode)/' '/opt/FreeRDP/server/FreeRDS/module/X11/service/rdpInput.c'

# Fix compilation error, a parameter in a pulseaudio function was removed (https://lists.freedesktop.org/archives/pulseaudio-discuss/2014-November/022324.html)
sed -i 's/pa_rtpoll_run(context->rtpoll, TRUE)/pa_rtpoll_run(context->rtpoll)/' '/opt/FreeRDP/server/FreeRDS/channels/rdpsnd/pulse/module-freerds-sink.c'

# Fix compilation error, pa_bool_t was removed from pulseaudio (https://lists.freedesktop.org/archives/pulseaudio-discuss/2012-July/013981.html)
sed -i 's/pa_bool_t/bool/' '/opt/FreeRDP/server/FreeRDS/channels/rdpsnd/pulse/module-freerds-sink-symdef.h'

# Fix linking error, pulsecore wasn't supposed to be a public lib, but FreeRDS used it anyway (https://lists.freedesktop.org/archives/pulseaudio-discuss/2015-December/024964.html)
sed -i 's/-lpulsecore-8.0//' '/opt/FreeRDP/server/FreeRDS/channels/rdpsnd/pulse/CMakeFiles/module-freerds-sink.dir/link.txt'

# Build FreeRDP (but don't install it, we don't need that!)
make


### Install the dependencies for QDCSVC

cd '/lib/x86_64-linux-gnu'

# These two are just using the existing libssl1.0.0, but QDCSVC expects a different version
ln -s 'libssl.so.1.0.0' 'libssl.so.10'
ln -s 'libcrypto.so.1.0.0' 'libcrypto.so.10'

# The reason we built FreeRDS in the first place
ln -s '/opt/FreeRDP/server/FreeRDS/fdsapi/libfreerds-fdsapi.so' 'libfreerds-fdsapi.so'
ln -s '/opt/FreeRDP/server/FreeRDS/freerds/rpc/libfreerds-rpc.so' 'libfreerds-rpc.so'
ln -s '/opt/FreeRDP/winpr/libwinpr/libwinpr.so.1.1.0' 'libwinpr.so.1.1'


### Install QDCSVC

# Install a systemd service
cat > '/etc/systemd/system/qdcsvc.service' << EOF
[Unit]
Description = QDCSVC systemd service

[Service]
Type=forking
ExecStart=/opt/VDEFORLINUX/VirtualDesktopExtension/x64/qdcsvc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable qdcsvc.service

# Install the config file for QDCSVC (with placeholders)
cp '/opt/VDEFORLINUX/Provisioning/qdcsvc.conf' '/etc/qdcsvc.conf'


### The rest of this script must be executed at the next boot

# We're going to parse XML, do it properly with xml_grep
apt install -y xml-twig-tools

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
net ads join -U "$UserName"%"$Password"
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


### Cleanup

# Remove temp files
rm -rf '/tmp/'*

# Remove logs, but leave directories untouched, they have special permissions so their associated software can't re-create them
find '/var/log' -type f -exec rm -f {} \;
