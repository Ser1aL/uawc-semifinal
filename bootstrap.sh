#!/usr/bin/env bash

apt-get update
apt-get install -y curl git gcc

# first try git clone
cd /opt
git clone https://Ser1al@github.com/Ser1aL/uawc-semifinal
cd uawc-semifinal

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable
source /usr/local/rvm/scripts/rvm
echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc

rvm install ruby-2.2.1
rvm use ruby-2.2.1@uawc-semifinal --default --create

bundle install

echo "======Debugging locales====="
echo "======> locale before change====="
locale
echo "======changing====="
cat >/etc/default/locale <<EOL
LANG=en_US.UTF-8
LANGUAGE=
LC_CTYPE=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_TIME=en_US.UTF-8
LC_COLLATE=en_US.UTF-8
LC_MONETARY=en_US.UTF-8
LC_MESSAGES=en_US.UTF-8
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=
EOL
source /etc/default/locale
echo "======> locale after change====="
locale
echo "======reloading shell====="
# hard reload the shell for locale changes to take effect
/bin/bash
echo "======> locale after reload====="
locale
echo "============================"
echo 'Starting services'
cd /opt/uawc-semifinal && ./restart_server.sh
echo 'Puma started!'

