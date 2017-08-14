#!/bin/sh
# Remove all locales except those passed as arguments, can save ~50 MB

if [ $# -eq 0 ]; then
  echo "This script takes the locales to keep as arguments" >&2
  exit 1
fi

# Pre-configure the package
debconf-set-selections << EOF
localepurge     localepurge/use-dpkg-feature    boolean false
localepurge     localepurge/showfreedspace      boolean true
localepurge     localepurge/dontbothernew       boolean false
localepurge     localepurge/nopurge             multiselect $@
localepurge     localepurge/none_selected       boolean false
localepurge     localepurge/mandelete           boolean true
localepurge     localepurge/remove_no           boolean false
localepurge     localepurge/quickndirtycalc     boolean false
localepurge     localepurge/verbose             boolean false
EOF

# Install it, run it, immediately uninstall it as we don't need to keep it
apt install -y localepurge
localepurge
apt purge -y localepurge
