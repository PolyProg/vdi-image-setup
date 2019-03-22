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

# Ask for credentials first
read -p 'User: ' User
read -p 'Password: ' Password

# Get AD servers
ADServers="$(dig +short _ldap._tcp.intranet.epfl.ch SRV | cut -d ' ' -f4 | sed -e 's/\.*$//')"

# HACK: Required given the EPFL setup - otherwise Kerberos servers can't be found by realmd
for Server in $ADServers; do
  ServerIp="$(nslookup $Server | sed -n '5p' | cut -d ' ' -f2)"
  echo "$ServerIp $Server" >> '/etc/hosts'
done

# Core install
./install.sh "$User" "$Password" \
             'INTRANET.EPFL.CH' \
             'OU=PolyProg,OU=StudentVDI,OU=VDI,OU=DIT-Services Communs,DC=intranet,DC=epfl,DC=ch'

# Remove timers, our machines are short-lived and we don't want anything messing them up
./remove/dangerous/timers.sh

# Basic utilities
./add/software/archiver.sh
./add/software/browser.sh
./add/software/pdf-reader.sh

# Programming languages
./add/languages/c_and_cpp.sh
./add/languages/java.sh
./add/languages/python2.sh
./add/languages/python3.sh

if [ "$1" = 'santa' ]; then
  ./add/languages/scala.sh
fi

# Dev tools
./add/software/atom.sh
./add/software/codeblocks.sh
./add/software/eclipse.sh
./add/software/emacs.sh
./add/software/geany.sh
./add/software/kate.sh
./add/software/netbeans.sh
./add/software/vim.sh
./add/software/vscode.sh

# Basic desktop panels
./configure/xfce-basic-panels.sh

# Contest and doc on the desktop
if [ "$1" = 'hc2' ]; then
  ContestHost='contest.hc2.ch'
  ./add/desktop-url.sh 'Contest' 'http://contest.hc2.ch'
else
  ContestHost='official.contest.yandex.com contest.yandex.com passport.yandex.com social.yandex.com yastatic.net yandex.st mc.yandex.ru clck.yandex.ru'
  ./add/desktop-url.sh 'Contest' 'https://official.contest.yandex.com/santa/'
fi

./add/desktop-url.sh 'Documentation' 'http://doc.hc2.ch'

# Configure firewall, in order:
# - apt repositories
# - Oracle javadocs (required for Eclipse to use it)
# - Documentation
# - Contest server
./configure/firewall.sh ch.archive.ubuntu.com security.ubuntu.com packages.microsoft.com \
                        docs.oracle.com \
                        doc.hc2.ch \
                        $ContestHost

# Final cleanup
./remove/locales.sh 'en, en_US.UTF_8'
./remove/doc.sh
./remove/temp-files.sh
# This needs to be last since other scripts assume apt-get works fine
./remove/apt-cache.sh
