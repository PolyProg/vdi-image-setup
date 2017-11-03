#!/bin/sh
# Build FreeRDP/FreeRDS from the vWorkspace repo, since QDCSVC, the Quest Data Collector Service
# which is used by vWorkspace, depends on that specific version of libwinpr, as well as on two freerds libs
# This is inspired from the FreeRDS scripts, but without the parts we don't need

# These two needs to be kept afterwards, so we install them right away
apt-get install -y libssl-dev libcurl3

# Other packages required by FreeRDP and FreeRDS (also git, since we're git-cloning stuff)
DepsPackages="build-essential cmake bison flex intltool \
              libboost-dev libexpat1-dev libfontconfig1-dev libfreetype6-dev libfuse-dev libgl1-mesa-dev libjpeg-dev libjson-c-dev libpam0g-dev \
              libpciaccess-dev libpixman-1-dev libpng12-dev libtool libsndfile1-dev libxml-libxml-perl \
              mesa-common-dev \
              x11proto-gl-dev xorg-dev xsltproc xutils-dev \
              libasound2-dev libavcodec-dev libavutil-dev libcups2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libpulse-dev \
              libx11-dev libxcursor-dev libxdamage-dev libxext-dev libxi-dev libxinerama-dev libxkbfile-dev libxrandr-dev libxrender-dev libxv-dev \
              libcap-dev libltdl-dev \
              git"

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

# Save the working directory to restore it later
WorkDir=$(pwd)

# Apparently this is required by FreeRDS (?)
export LD_LIBRARY_PATH=/usr/lib

# Clone FreeRDP, then FreeRDS as a subfolder (yes, that's normal)
cd '/opt'
git clone https://github.com/vworkspace/FreeRDP.git --branch awakecoding --single-branch
cd 'FreeRDP/server'
git clone https://github.com/vworkspace/FreeRDS.git --branch awakecoding --single-branch

# Remove the FreeRDS Greeter, which depends on QT for... a timer.
# Otherwise it requires downloading all of QT just for a greeter we don't even use.
sed -i 's/add_subdirectory(widgets)//g' FreeRDS/CMakeLists.txt

cd '/opt/FreeRDP/server/FreeRDS/module/X11/service/xorg-build'
cmake .
make
cd ..
# magic, comes from the FreeRDS install docs (https://github.com/awakecoding/FreeRDP-Manuals/blob/master/Developer/FreeRDP-Developer-Manual.markdown)
ln -s 'xorg-build/external/Source/xorg-server' .

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

cd '/lib/x86_64-linux-gnu'

# These two are just using the existing libs, but QDCSVC expects a different version
ln -s 'libssl.so.1.0.0' 'libssl.so.10'
ln -s 'libcrypto.so.1.0.0' 'libcrypto.so.10'

# The reason we built FreeRDS in the first place
cp '/opt/FreeRDP/server/FreeRDS/fdsapi/libfreerds-fdsapi.so' 'libfreerds-fdsapi.so'
cp '/opt/FreeRDP/server/FreeRDS/freerds/rpc/libfreerds-rpc.so' 'libfreerds-rpc.so'
cp '/opt/FreeRDP/winpr/libwinpr/libwinpr.so.1.1.0' 'libwinpr.so.1.1'

# No need for FreeRDP now, and it takes up half a gigabyte...
rm -rf '/opt/FreeRDP'

# Remove the dependencies' packages, since only care about 3 libs that do not require them (except libssl, as noted above)
apt-get purge -y $PackagesToInstall
apt-get autoremove -y --purge

# Restore the working directory
cd "$WorkDir"
