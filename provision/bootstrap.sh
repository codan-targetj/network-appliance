#!/bin/sh

## Base system and tooling

apt-get -qq update
apt-get -qq install -y \
            freeradius \
            openssl \
            dnsmasq
            
su -c "source /vagrant/provision/configure-freeradius.sh" root

echo "Starting freeradius..."
freeradius -X &
