#!/bin/sh

## Base system and tooling

echo "Update apt cache..."
apt-get -qq update
echo "Install base packages..."
apt-get -qq install -y \
            freeradius \
            openssl \
            dnsmasq \
            >/dev/null 2>&1
            
su -c "source /vagrant/provision/place-certificates.sh" root
su -c "source /vagrant/provision/configure-freeradius.sh" root

echo "Starting freeradius..."
freeradius -X &
