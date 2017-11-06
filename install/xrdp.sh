#!/bin/sh
# Install xrdp

# Save the working directory to restore it later
WorkDir=$(pwd)

# Packages that are only needed to build
DepsPackages="git gcc make autoconf automake libtool pkgconf nasm"

# Figure out which packages we need to actually install, so we can remove them afterwards
AptOutput=$(apt-get install $DepsPackages --dry-run -qq)
PackagesToInstall=""
for pkg in $DepsPackages; do
  if echo "$AptOutput" | grep -q "Inst $pkg"; then
    PackagesToInstall="$PackagesToInstall $pkg"
  fi
done

# Install them
apt-get install -y $PackagesToInstall

# Other dependencies, as per the xrdp and xorgxrdp READMEs
# Technically we don't need the -dev parts after building,
# but let's not bother chasing down all real dependencies for a tiny amount of space
apt-get install -y libssl-dev libpam0g-dev \
                   libx11-dev libxfixes-dev libxrandr-dev \
                   xserver-xorg-dev

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
cat > '/etc/xrdp/xrdp.sh' << 'EOF'
# This script has been replaced by a systemd wrapper
systemctl $1 xrdp
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

# Cleanup
rm -rf '/opt/xrdp'
rm -rf '/opt/xorgxrdp'
apt-get purge -y --autoremove $PackagesToInstall

# Restore the working directory
cd "$WorkDir"
