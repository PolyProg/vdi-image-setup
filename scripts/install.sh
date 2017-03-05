#!/bin/sh

### Check for prerequisites
### First the platform, then the stuff that can be changed

if [ ! -e /usr/bin/lsb_release ]; then
  echo "Please run this script under Ubuntu" >&2
  exit 1
fi

case `lsb_release -d` in
  *"Ubuntu 16.04"*)
    :
    ;;
  *)
    echo "Please run this script under Ubuntu 16.04" >&2
    exit 2
    ;;
esac

if [ `uname -i` != "x86_64" ]; then
  echo "Please run this script on an x64 OS" >&2
  exit 3
fi

NET_IFACE=`ls /sys/class/net | grep -v lo`
if [ `echo "$NET_IFACE" | wc -l` -ne "1" ]; then
  echo "Please run this script in a machine with only 1 interface (apart from loopback)" >&2
  exit 4
fi

if [ $EUID -ne 0 ]; then
  echo "Please run this script as root" >&2
  exit 5
fi

if [ ! -d /opt/VDEFORLINUX ]; then
  echo "Please put the vWorkspace VDEFORLINUX folder in /opt/VDEFORLINUX" >&2
  exit 6
fi

# TODO check vWorkspace expected version (8.6.1) - but how?


### Install git, since the software this script installs is git-cloned

apt install -y git


### Change the QCPIP script for our needs

# Change the root directory to /opt
sed -i 's/ROOTDIR=.*$/ROOTDIR="\/opt"/' /opt/VDEFORLINUX/Provisioning/vwts.all

# Set the XRDP dependencies to the latest ones, from https://github.com/neutrinolabs/xrdp/wiki/Building-on-Debian-8
sed -i 's/xrdppkgsDeb=.*$/xrdppkgsDeb="autoconf bison flex gcc g++ git intltool libfuse-dev libjpeg-dev libmp3lame-dev libpam0g-dev libpixman-1-dev libssl-dev libtool libx11-dev libxfixes-dev libxml2-dev libxrandr-dev make nasm pkg-config python-libxml2 xserver-xorg-dev xsltproc xutils xutils-dev"/' /opt/VDEFORLINUX/Provisioning/vwts.all

# Download XRDP ourselves, the script will use it
git clone https://github.com/neutrinolabs/xrdp.git /opt/xrdp.git

# Patch the XRDP source to increase the timeout for creating a session
# xauth takes quite a while...
sed -i 's/i > 40/i > 9999/' /opt/xrdp.git/sesman/session.c

### Work around QDCIP issues

# Replace hostname.service (unused, points to /dev/null) with systemd-logind.service
# since QDCIP uses it after changing the hostname
rm /lib/systemd/system/hostname.service
ln -s /lib/systemd/system/systemd-logind.service /lib/systemd/system/hostname.service

# Log the list of Active Directory servers... which has the side effect of taking some time,
# so that the actual attempt later is successful. Yes, this is weird.
sed -i '/getadsrv() {/a MyLogger "$(dig +short _ldap._tcp.${FQDNDom,,} SRV)"' /opt/VDEFORLINUX/Provisioning/qdcip.all

# Fool the script into believing QDCSVC is installed in /etc/init.d even though we made it a systemd service
cat > /etc/init.d/qdcsvc.sh << EOF
# This script does nothing, it's only there to fool QDCIP
# The real script is a systemd service named qdcsvc.service
EOF
chmod 777 /etc/init.d/qdcsvc.sh

# Fix a Samba problem with DNS not being found (see https://wiki.samba.org/index.php/Troubleshooting_Samba_Domain_Members)
# Yes, this is ugly as hell; it inserts bash commands after a specific point in the script, and only $NET_IFACE is actually replaced now
sed -i "/\# Join AD Domain using net command/a\\
DNS_IP=\`ifconfig $NET_IFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print \$1}'\`\\
DNS_FULL=\`hostname\`\\
DNS_SHORT=\`hostname | cut -d \".\" -f 1\`\\
echo \"\$DNS_IP \$DNS_FULL \$DNS_SHORT\" >> /etc/hosts" /opt/VDEFORLINUX/Provisioning/qdcip.all


### Build FreeRDP/FreeRDS from the vWorkspace repo, since QDCSVC depends on that specific version of libwinpr, as well as on two freerds libs
### This is inspired from the FreeRDS scripts, but without the parts we don't need

# Apparently this is required by FreeRDS (?)
export LD_LIBRARY_PATH=/usr/lib

# Required to build
apt install -y build-essential cmake

# Clone FreeRDP, then FreeRDS as a subfolder (yes, that's normal)
cd /opt
git clone https://github.com/vworkspace/FreeRDP.git --branch awakecoding --single-branch
cd FreeRDP/server
git clone https://github.com/vworkspace/FreeRDS.git --branch awakecoding --single-branch

# Fix compilation error, a parameter in an Xorg function was removed (https://lists.x.org/archives/xorg-devel/2014-December/044896.html)
sed -i 's/GetKeyboardEvents(pEventList, g_keyboard, type, scancode, NULL)/GetKeyboardEvents(pEventList, g_keyboard, type, scancode)/' /opt/FreeRDP/server/FreeRDS/module/X11/service/rdpInput.c

# Fix compilation error, a parameter in a pulseaudio function was removed (https://lists.freedesktop.org/archives/pulseaudio-discuss/2014-November/022324.html)
sed -i 's/pa_rtpoll_run(context->rtpoll, TRUE)/pa_rtpoll_run(context->rtpoll)/' /opt/FreeRDP/server/FreeRDS/channels/rdpsnd/pulse/module-freerds-sink.c

# Fix compilation error, pa_bool_t was removed from pulseaudio (https://lists.freedesktop.org/archives/pulseaudio-discuss/2012-July/013981.html)
sed -i 's/pa_bool_t/bool/' /opt/FreeRDP/server/FreeRDS/channels/rdpsnd/pulse/module-freerds-sink-symdef.h

# Fix linking error, pulsecore wasn't supposed to be a public lib, but FreeRDS used it anyway... (https://lists.freedesktop.org/archives/pulseaudio-discuss/2015-December/024964.html)
sed -i 's/-lpulsecore-8.0//' /opt/FreeRDP/server/FreeRDS/channels/rdpsnd/pulse/CMakeFiles/module-freerds-sink.dir/link.txt

# Not in the official dependencies list, but required anyway
apt install -y libcap-dev

# Build FreeRDS first, since it's a sub-thing
apt install -y bison flex intltool qt4-dev-tools libboost-dev libexpat1-dev libfontconfig1-dev libfreetype6-dev libfuse-dev libgl1-mesa-dev libjpeg-dev libjson-c-dev libpam0g-dev libpciaccess-dev libpixman-1-dev libpng12-dev libtool libsndfile1-dev libxml-libxml-perl mesa-common-dev x11proto-gl-dev xorg-dev xsltproc xutils-dev 
cd /opt/FreeRDP/server/FreeRDS/module/X11/service/xorg-build
cmake .
make
cd ..
# magic, comes from the FreeRDS install docs (https://github.com/awakecoding/FreeRDP-Manuals/blob/master/Developer/FreeRDP-Developer-Manual.markdown)
ln -s xorg-build/external/Source/xorg-server .

# Build FreeRDP with FreeRDS (but don't install it, we don't need that!)
apt install -y libasound2-dev libavcodec-dev libavutil-dev libcups2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libpulse-dev libssl-dev libx11-dev libxcursor-dev libxdamage-dev libxext-dev libxi-dev libxinerama-dev libxkbfile-dev libxrandr-dev libxrender-dev libxv-dev 
cd /opt/FreeRDP
cmake -DWITH_SERVER=on -DWITH_XRDS=on .
make


### Install VMware tools
apt install -y open-vm-tools-desktop


### Install the dependencies for QDCSVC

cd /lib/x86_64-linux-gnu

# These two are just using the existing libssl1.0.0, but QDCSVC expects a different version
ln -s libssl.so.1.0.0 libssl.so.10
ln -s libcrypto.so.1.0.0 libcrypto.so.10

# The reason we built FreeRDS in the first place
ln -s /opt/FreeRDP/server/FreeRDS/fdsapi/libfreerds-fdsapi.so libfreerds-fdsapi.so
ln -s /opt/FreeRDP/server/FreeRDS/freerds/rpc/libfreerds-rpc.so libfreerds-rpc.so
ln -s /opt/FreeRDP/winpr/libwinpr/libwinpr.so.1.1.0 libwinpr.so.1.1


### Run the provisioning script

# Get in the right directory first, this is required
cd /opt/VDEFORLINUX/Provisioning
./vwts.all xrdp

# Remove the copy of the qdcip script in bin, no point in it being there
rm /usr/local/bin/qdcip.all

# Remove some upstart stuff that's not needed and would only cause havoc if it ran
rm /etc/init/vW_provision.conf
rm /etc/init/vW_provision-wait.conf

# Create a systemd service instead of the upstart stuff
cat > /etc/systemd/system/qdcip.service << EOF
[Unit]
Description=QDCIP systemd service
After = NetworkManager-wait-online.service
Wants = NetworkManager-wait-online.service

[Service]
ExecStart=/opt/VDEFORLINUX/Provisioning/qdcip.all

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable qdcip.service


### Install QDCSVC as a systemd service

# Make it depend on qdcip since qdcip expects to run first
cat > /etc/systemd/system/qdcsvc.service << EOF
[Unit]
Description=QDCSVC systemd service
After = qdcip.service

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


### Enable, fix and configure xrdp

# For some reason xrdp stuff is in /usr/local/sbin but expected to be in /usr/sbin
ln -s /usr/local/sbin/xrdp /usr/sbin/xrdp
ln -s /usr/local/sbin/xrdp-chansrv /usr/sbin/xrdp-chansrv
ln -s /usr/local/sbin/xrdp-sesman /usr/sbin/xrdp-sesman
ln -s /usr/local/sbin/xrdp-sessvc /usr/sbin/xrdp-sessvc

# The QDCSVC script attempts to create an init.d start entry, but that doesn't work on Ubuntu 16.04
# Instead, XRDP creates systemd services

# We really want XRDP (and its session manager) to be restarted if it dies
sed -i '/\[Service\]/a Restart=always' /lib/systemd/system/xrdp.service
sed -i '/\[Service\]/a Restart=always' /lib/systemd/system/xrdp-sesman.service

# Apply the changes, and enable XRDP
systemctl daemon-reload
systemctl enable xrdp.service
systemctl enable xrdp-sesman.service

# The xrdp.sh script is an old thing that shouldn't be used any more; replace it with a systemd shim
# Otherwise, `xrdp.sh restart` hangs because it waits for xrdp to stop but we made it `Restart=always` above
cat > /etc/xrdp/xrdp.sh << EOF
# This script has been replaced by a systemd wrapper
systemctl \$1 xrdp
EOF

# Disable the LightDM service, the VM is never getting connected to directly
systemctl disable lightdm

# Set the proper config
cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.ORIG
cat > /etc/xrdp/xrdp.ini << EOF
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
max_bpp=24
use_fastpath=both

autorun=X11rdp

; These three are set in the default config, not sure if they're important
new_cursors=true
blue=009cb5
grey=dedede

[Logging]
EnableSyslog=true
SyslogLevel=DEBUG

; Sound (rdpsnd) is disabled, it causes problems
[Channels]
rdpdr=true
rdpsnd=false
drdynvc=true
cliprdr=true
rail=true
xrdpvr=true
tcutils=true

[X11rdp]
name=X11rdp
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
xserverbpp=24
code=10
EOF


### Cleanup

# Remove temp files
rm -rf /tmp/*

# Remove vwts log files
rm -f /opt/log_vwts_*

# Remove logs, but leave directories untouched, some software (e.g. samba) complains about missing its log dir otherwise
find /var/log -type f -exec rm -f {} \;
