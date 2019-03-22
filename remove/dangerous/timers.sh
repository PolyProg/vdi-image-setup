#!/bin/sh
# Removes all timed actions from the system

apt purge -y --autoremove cron logrotate

for $Timer in 'systemd-tmpfiles-clean' 'apt-daily' 'apt-daily-upgrade' 'fstrim' 'motd-news' 'ureadahead-stop'; do
  systemctl mask "$Timer.timer"
done
