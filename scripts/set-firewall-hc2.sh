#!/bin/sh
# Firewall rules for the Helvetic Coding Contest, an example of how to use set-firewall

if [ ! -f "set-firewall.sh" ]; then
  echo "Please execute this script in the same directory as set-firewall" >&2
  exit 1
fi

# In order:
# - VDI connection brokers
# - VDI web access
# - HC2 documentation, contest, and replica
./set-firewall.sh itvdiconnect01.epfl.ch itvdiconnect02.epfl.ch itvdiconnect03.epfl.ch itvdiconnect04.epfl.ch \
                  itvdiweb01.epfl.ch itvdiweb02.epfl.ch vdi.epfl.ch \
                  doc.hc2.ch contest.hc2.ch repl.hc2.ch
