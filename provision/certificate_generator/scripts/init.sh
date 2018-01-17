#!/bin/bash

ROOT=`pwd`
CONFIG_DIR=$ROOT/configs
CA_DIR=$ROOT/CA
CA_KEYS_DIR=$CA_DIR/keys
CA_CLIENT_KEYS_DIR=$CA_KEYS_DIR/clients
CA_ISSUE_DIR=$CA_DIR/issue

CERTS_DIR=$ROOT/certs
NEW_CERTS_DIR=$ROOT/new_certs
TEMP_DIR=/tmp/certstore

PASS_DIR=$CA_DIR

NO_PASS=true #force true until make_clients.sh update to account for password protected key files

USER=`/usr/bin/id -run`

if [ "$EUID" -ne 0 ] ; then
	echo "Script must be exectued as root!"
	exit 0
fi

while [ $# -ne 0 ]
do
	case $1 in 
		"-nopass")
			NO_PASS=true
		;;
	esac
	shift
done



# Functions
gen_random_passphrase() {
	PP_FILE=$1
	PP_SIZE=$2
	PP_SIZE=${PP_SIZE:-32}
	echo $PP_FILE $PP_SIZE
	PASSPHRASE=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$PP_SIZE" | head -n 1`
	echo $PASSPHRASE > "$1"
}


# Make the required directories, if they don't exist
ALL_DIRS=($CA_DIR $CA_KEYS_DIR $CA_CLIENT_KEYS_DIR $CA_ISSUE_DIR $CERTS_DIR $NEW_CERTS_DIR $TEMP_DIR)
NEW_DIR_COUNT=0

echo $USER:$USER
echo "Checking for required directories..."
for dir in "${ALL_DIRS[@]}"
do
	if [ ! -d $dir ] ; then
		NEW_DIR_COUNT=$((NEW_DIR_COUNT+1))
		echo "Creating directory: $dir"
		mkdir $dir
		chown $USER:$USER $dir
		chmod 600 $dir
	fi
done

echo "Checking for required files..."
if [ ! -f $CA_ISSUE_DIR/index.txt ] ; then
	touch $CA_ISSUE_DIR/index.txt
	chmod 600 $CA_ISSUE_DIR/index.txt
	echo "Created $CA_ISSUE_DIR/index.txt"
fi
if [ ! -f $CA_ISSUE_DIR/serial.txt ] ; then
	echo "10000001" > $CA_ISSUE_DIR/serial.txt
	chmod 600 $CA_ISSUE_DIR/serial.txt
	echo "Created $CA_ISSUE_DIR/serial.txt"
fi

# Generate Random Passphrase for Certificate Authority
gen_random_passphrase $PASS_DIR/ca.pp 64

# Create a self-signed certificate to act as Certificate Authority
echo "Creating self-signed Certificate Authority..."
if [ $NO_PASS = false ] ; then
	openssl req -new -x509 -config $CONFIG_DIR/ca.cnf -out $CA_DIR/ca_cert.pem -passout file:$PASS_DIR/ca.pp -batch
else
	openssl req -new -x509 -config $CONFIG_DIR/ca.cnf -out $CA_DIR/ca_cert.pem -nodes -batch
fi 

# Generate Random Passphrase for Server CSR
gen_random_passphrase $PASS_DIR/server.pp 64

# Create a CSR for the server
echo "Creating Certificate Sign Request (CSR) for the server..."
if [ $NO_PASS = false ] ; then
	openssl req -new -config $CONFIG_DIR/server.cnf -out $CA_DIR/server_req.csr -passout file:$PASS_DIR/server.pp -batch
else
	openssl req -new -config $CONFIG_DIR/server.cnf -out $CA_DIR/server_req.csr -nodes -batch
fi

# Sign the Server CSR with CA, using ca.cnf
SERIAL_NUMBER=`cat $CA_ISSUE_DIR/serial.txt`
echo "Signing the server CSR..."
if [ $NO_PASS = false ] ; then 
	openssl ca -config $CONFIG_DIR/ca.cnf -passin file:$PASS_DIR/ca.pp -policy signing_policy -extensions signing_req -out $NEW_CERTS_DIR/server_cert.pem -in $CA_DIR/server_req.csr
else
	openssl ca -config $CONFIG_DIR/ca.cnf -policy signing_policy -extensions signing_req -out $NEW_CERTS_DIR/server_cert.pem -in $CA_DIR/server_req.csr
fi

mv $NEW_CERTS_DIR/server_cert.pem $CERTS_DIR/server_cert.pem
rm -rf $NEW_CERTS_DIR/$SERIAL_NUMBER.pem
rm -rf $CA_DIR/server_req.csr

echo "Done."