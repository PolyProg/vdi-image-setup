#!/bin/sh
# Adds an URL on the desktop, with name $1 and url $2

if [ $# -ne 2 ]; then
  echo "This script takes the name and URL as argument" >&2
  exit 1
fi

# Create the default Desktop dir if it doesn't exist
mkdir -p '/etc/skel/Desktop'

# Add our minimal desktop file
cat > "/etc/skel/Desktop/$1.desktop" << EOF
[Desktop Entry]
Encoding=UTF-8
Name=$1
Type=Link
URL=$2
Icon=text-html
EOF

# Make it executable, otherwise there's a message box before opening it
chmod 777 "/etc/skel/Desktop/$1.desktop"

# Install it for root as well
mkdir -p '/root/Desktop'
cp "/etc/skel/Desktop/$1.desktop" "/root/Desktop/$1.desktop"
