#!/bin/sh
# Removes all timed actions from the system

apt purge -y --autoremove cron logrotate
systemctl mask systemd-tmpfiles-clean.timer
systemctl mask apt-daily.timer
systemctl mask apt-daily-upgrade.timer
