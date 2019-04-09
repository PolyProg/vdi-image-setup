#!/bin/sh
# Configures XFCE to only allow logout, not shutdown/restart or session save

mkdir -p '/etc/xdg/xfce4/kiosk'
cat > '/etc/xdg/xfce4/kiosk/kioskrc' << EOF
[xfce4-session]
Shutdown=
SaveSession=NONE
EOF
