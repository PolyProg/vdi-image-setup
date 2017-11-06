#!/bin/sh
# Removes all traces of Python on a fresh Ubuntu mini install.
# This removes stuff like lsb_release...

apt purge -y --autoremove '*python*'
