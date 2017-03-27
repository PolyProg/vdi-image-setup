#!/bin/sh
# Sets the default keyboard

if [ $# -eq 0 ]; then
  echo "This script takes the keyboard as argument >&2
  exit 1
fi

cat > /opt/keyboard.sh << EOF
#!/bin/sh

# sleep is required for it to work... for some reason.
sleep 2
setxkbmap $@
EOF

cat > /etc/xdg/autostart/Keyboard.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Script
Type=Application
Exec=/opt/keyboard.sh
Terminal=false
StartupNotify=false
Hidden=false
EOF
