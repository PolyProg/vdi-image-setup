#!/bin/sh
# Sets the desktop background to the given URL

if [ $# -ne 1 ]; then
  echo "This script expects an URL as its single argument." >&2
  exit 1
fi

wget -O '/opt/background' "$1"

cat > '/usr/share/glib-2.0/schemas/99desktop-background.gschema.override' << EOF
[org.gnome.desktop.background]
zoom='scaled'
picture-uri='file:///opt/background'
EOF
glib-compile-schemas '/usr/share/glib-2.0/schemas/'
