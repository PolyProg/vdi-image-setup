#!/bin/sh
# PolyProg install script

if [ ! -x 'install.sh' ]; then
  echo 'Please execute this script in the same directory as install.sh' >&2
  exit 1
fi

if [ $# -eq 0 -o \( "$1" != 'santa' -a "$1" != 'hc2' \) ]; then
  echo "Expected single argument: one of 'santa', 'hc2'" >&2
  exit 1
fi

# Remove unneeded components first
./remove/dangerous/python.sh
./remove/dangerous/timers.sh

# Install the OS
./install.sh

# Basic utilities
./add/software/archiver.sh
./add/software/browser.sh
./add/software/pdf-reader.sh

# Programming languages
./add/languages/c_and_cpp.sh
./add/languages/java.sh
./add/languages/python2.sh

if [ "$1" = 'hc2' ]; then
  ./add/languages/python3.sh
else
  ./add/languages/obsolete/python3.2.sh
  ./add/languages/scala.sh
fi

# Dev tools
./add/software/codeblocks.sh
./add/software/eclipse.sh
./add/software/emacs.sh
./add/software/geany.sh
./add/software/netbeans.sh
./add/software/vim.sh

# Salt
./add/software/salt.sh 'master.hc2.ch'

# Basic desktop panels
./configure/xfce-basic-panels.sh

# Contest and doc on the desktop
if [ "$1" = 'hc2' ]; then
  CONTEST_HOST='contest.hc2.ch replica.hc2.ch'
  ./add/desktop-url.sh 'Contest' 'http://contest.hc2.ch'
else
  CONTEST_HOST='official.contest.yandex.com contest.yandex.com passport.yandex.com social.yandex.com yastatic.net yandex.st mc.yandex.ru clck.yandex.ru'
  ./add/desktop-url.sh 'Contest' 'https://official.contest.yandex.com/santa/'
fi

./add/desktop-url.sh 'Documentation' 'http://doc.hc2.ch'

# Swiss keyboard
./configure/keyboard.sh 'ch' 'fr'

# Configure firewall, in order:
# - apt repositories
# - Oracle javadocs (required for Eclipse to use it)
# - VDI connection brokers
# - VDI web access
# - HC2 saltmaster, documentation
# - Contest server
./configure/firewall.sh ch.archive.ubuntu.com security.ubuntu.com ppa.launchpad.net repo.saltstack.com \
                        docs.oracle.com \
                        itvdiconnect01.epfl.ch itvdiconnect02.epfl.ch itvdiconnect03.epfl.ch itvdiconnect04.epfl.ch \
                        itvdiweb01.epfl.ch itvdiweb02.epfl.ch vdi.epfl.ch \
                        master.hc2.ch doc.hc2.ch \
                        $CONTEST_HOST

# Remove documentation, we don't need it (only man pages)
./remove/doc.sh

# Remove locales other than English
./remove/locales.sh 'en, en_US.UTF_8'

# Final cleanup
./remove/unused-packages.sh
./remove/apt-cache.sh
./remove/temp-files.sh
