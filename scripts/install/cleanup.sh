#!/bin/sh
# Cleanup leftovers from the installation

# Remove temp files
rm -rf '/tmp/'*

# Remove logs, but leave directories untouched, they have special permissions so their associated software can't re-create them
find '/var/log' -type f -exec rm -f {} \;
