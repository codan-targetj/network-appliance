#! /bin/sh


# FreeRADIUS files can only be modified by root. For security reasons,
# permissions should be as restrictive as possible.

DIR=/etc/freeradius
dh_bits=128

echo "Generate a Diffie-Hellman cipher file. This may take a long time..."
openssl dhparam -check -text -5 $dh_bits -out $DIR/certs/dh

echo "Setting config in radiusd.conf"
sed -i '/max_requests = /c\max_requests = 7680' $DIR/radiusd.conf
sed -i '/type = auth/a 	virtual_server = wifiwasp_network' $DIR/radiusd.conf

echo "
server wifiwasp_network {
  authorize {
    preprocess
    eap {
      ok = return
    }
    expiration
    logintime
  }
  authenticate {
    eap
  }
  preacct {
    preprocess
    acct_unique
    suffix
    files
  }
  accounting {
    ok
  }
  session {
    radutmp
  }
  post-auth {
    exec
    Post-Auth-Type REJECT {
      attr_filter.access_reject
    }
  }
  pre-proxy {
  }
  post-proxy {
    eap
  }
}
" >> $DIR/radiusd.conf

echo "Replacing eap.conf"
mv $DIR/eap.conf $DIR/eap_original.conf
cp /vagrannt/provision/eap.conf $DIR/eap.conf

echo "Setting subnet range and configuration parameters for the network using EAP authentication"
echo "
client 10.96.0.0/11 {
    secret = wifiwasp
    shortname = wifiwasp-net
    nastype = other
}
" >> $DIR/clients.conf

echo "Remove all simlinks in sites-enabled to remove additional behaviours we don't need"
rm $DIR/sites-enabled/*

echo "Set permissions on the files in the /etc/freeradius directory to protect them"
chown -R freerad:freerad /etc/freeradius
chmod -R 0700 /etc/freeradius
chmod 0400 /etc/freeradius/*.conf
chmod 0400 /etc/freeradius/certs/*

echo "FreeRADIUS configuration complete."










