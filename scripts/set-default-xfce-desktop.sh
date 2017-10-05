#!/bin/sh
# Sets the default XFCE desktop configuration (so new users don't get prompts)

if [ ! -d files ]; then
  echo "Please run this script from the 'scripts' directory, where there is a 'files' directory" >&2
  exit 1
fi

# Set the panels
mkdir /etc/skel/.config
cp -r files/xfce4/ /etc/skel/.config/
mkdir /root/.config
cp -r files/xfce4/ /root/.config/

# Set the menu
mkdir /etc/skel/.config/menus
cp files/xfce-applications.menu /etc/skel/.config/menus/
mkdir /root/.config/menus
cp files/xfce-applications.menu /root/.config/menus/
