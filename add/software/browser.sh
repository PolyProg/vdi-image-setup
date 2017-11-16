#!/bin/sh
# Installs a web browser
# Notes:
# - Firefox pulls in lsb-release which includes python3
# - Midori doesn't work with invalid SSL certs, has some obscure instructions on how to install something to store exceptions
# So we use Epiphany instead.

apt-get install -y epiphany-browser
