#!/bin/sh
# Python 3.2 language support, latest available on contest.yandex.com as of 2016-11-16

NeedSpc=0
if [ ! -x "$(command -v add-apt-repository)" ]; then
  apt-get install -y software-properties-common
  NeedSpc=1
fi


add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.2


if [ $NeedSpc -eq 1 ]; then
  apt-get purge --autoremove -y software-properties-common
fi
