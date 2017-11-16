#!/bin/sh
# Python 3.2 language support, latest available on contest.yandex.com as of 2016-11-16

apt-get update
apt-get install -y software-properties-common # for add-apt-repository
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.2
