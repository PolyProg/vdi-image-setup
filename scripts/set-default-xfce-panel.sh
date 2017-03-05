#!/bin/sh
# Sets the default XFCE panels (so new users don't get prompts)

if [ ! -d files ] || [ ! -d files/xfce4 ]; then
  echo "Please run this script from the 'scripts' directory, where there is a 'files/xfce4' directory" >&2
  exit 1
fi

cp -r files/xfce4 /etc/skel/.config
