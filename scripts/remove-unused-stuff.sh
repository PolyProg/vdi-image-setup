#!/bin/sh
# Removes unused stuff

### Remove unused locales (~40 MB!)

debconf-set-selections << EOF
localepurge     localepurge/use-dpkg-feature    boolean false
localepurge     localepurge/showfreedspace      boolean true
localepurge     localepurge/dontbothernew       boolean false
localepurge     localepurge/nopurge             multiselect en, en_US.UTF-8
localepurge     localepurge/none_selected       boolean false
localepurge     localepurge/mandelete           boolean true
localepurge     localepurge/remove_no           boolean false
localepurge     localepurge/quickndirtycalc     boolean false
localepurge     localepurge/verbose             boolean false
EOF
apt install -y localepurge
localepurge
apt purge -y localepurge


### Autoremove anything that can be

apt autoremove -y --purge
