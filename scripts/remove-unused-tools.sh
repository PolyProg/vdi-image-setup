#!/bin/sh
# Removes unused tools


### Removes the mail client shortcut, unused (and useless by default since there is no mail client in xubuntu-core)

rm /usr/share/applications/exo-mail-reader.desktop


### Remove the "About XFCE" shortcut, useless

rm /usr/share/applications/xfce4-about.desktop


### Uninstalls QT4 tools, which come with xubuntu-core

apt purge -y qt4-dev-tools
apt autoremove -y --purge
