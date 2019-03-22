#!/bin/sh
# Sets the keyboard layout

if [ $# -ne 1 ]; then
  echo 'This script requires the layout as argument.'
  exit 1
fi

cat > '/opt/keyboard.sh' << EOF
#!/bin/sh

# sleep is required for it to work... for some reason.
sleep 2
setxkbmap $1
EOF

chmod 755 '/opt/keyboard.sh'

mkdir -p '/etc/skel/.config/autostart'
cat > '/etc/skel/.config/autostart/Keyboard.desktop' << EOF
[Desktop Entry]
Version=1.0
Name=Script
Type=Application
Exec=/opt/keyboard.sh
Terminal=false
StartupNotify=false
Hidden=false
EOF

chmod 755 '/etc/skel/.config/autostart/Keyboard.desktop'

# Make it work for root as well
mkdir -p '/root/.config/autostart'
cp '/etc/skel/.config/autostart/Keyboard.desktop' '/root/.config/autostart/Keyboard.desktop'
