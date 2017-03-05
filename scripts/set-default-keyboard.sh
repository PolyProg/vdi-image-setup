#!/bin/sh
# Sets the default keyboard


if [ $# -eq 0 ]; then
  echo "This script takes the keyboard as argument" >&2
  exit 1
fi

cat > /etc/xdg/autostart/setxkbmap.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Exec=setxkbmap $*
Name=Keyboard update
Comment=Update keyboard layout
Terminal=false
Type=Application
StartupNotify=false
NoDisplay=true
EOF
