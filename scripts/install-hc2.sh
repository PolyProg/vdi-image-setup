#!/bin/sh
# Example of how to write a custom script that installs and configures software

if [ ! -f "install.sh" ]; then
  echo "Please execute this script in the same directory as install.sh" >&2
  exit 1
fi

# First things first
./install.sh

# Basic utilities
./add/archiver.sh
./add/browser.sh
./add/pdf-reader.sh

# Dev tools
./add/codeblocks.sh
./add/eclipse.sh
./add/emacs.sh
./add/geany.sh
./add/netbeans.sh
./add/vim.sh

# Salt
./add/salt.sh 'master.hc2.ch'

# Basic desktop panels
./configure/xfce-basic-panels.sh

# Contest and doc on the desktop
./add/desktop-url.sh 'Contest' 'http://contest.hc2.ch'
./add/desktop-url.sh 'Documentation' 'http://doc.hc2.ch'

# Swiss keyboard
./configure/keyboard.sh 'ch' 'fr'

# Configure firewall, in order:
# - apt repositories
# - VDI connection brokers
# - VDI web access
# - HC2 saltmaster, documentation, contest, and replica
./configure/firewall.sh ch.archive.ubuntu.com security.ubuntu.com repo.saltstack.com \
                        itvdiconnect01.epfl.ch itvdiconnect02.epfl.ch itvdiconnect03.epfl.ch itvdiconnect04.epfl.ch \
                        itvdiweb01.epfl.ch itvdiweb02.epfl.ch vdi.epfl.ch \
                        master.hc2.ch doc.hc2.ch contest.hc2.ch repl.hc2.ch

# Remove documentation, we don't need it (only man pages)
./remove/doc.sh

# Remove locales other than English
./remove/locales.sh 'en, en_US.UTF_8'

# Remove unused packages
./remove/unused-packages.sh

# Remove apt cache
./remove/apt-cache.sh
