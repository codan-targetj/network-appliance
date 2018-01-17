#! /bin/sh

dest=/etc/freeradius/certs

/vagrant/provision/certificate_generator/scripts/restore.sh -y
/vagrant/provision/certificate_generator/scripts/init.sh -nopass -batch
/vagrant/provision/certificate_generator/scripts/make_clients.sh -nopass -batch -c 1

echo "Deleting default certificates and keys"
rm -rf $dest/ca.pem $dest/server.key $dest/server.pem

echo "Copy the certificates into the FreeRADIUS directory"
cp /vagrant/provision/certificate_generator/CA/ca_cert.pem $dest/ca_cert.pem
cp /vagrant/provision/certificate_generator/CA/keys/server_key.pem $dest/server_key.pem
cp /vagrant/provision/certificate_generator/certs/server_cert.pem $dest/server_cert.pem

echo "Set permissions on files"
chown -R freerad:freerad $dest