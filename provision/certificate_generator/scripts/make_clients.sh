#!/bin/bash


NUM_CERTS=1
COMMON_NAME_PREFIX="WiFiWASP"

ROOT=/vagrant/provision/certificate_generator
CONFIG_DIR=$ROOT/configs
CA_DIR=$ROOT/CA
CA_ISSUE_DIR=$CA_DIR/issue
CA_KEYS_DIR=$CA_DIR/keys
CA_CLIENT_KEYS_DIR=$CA_KEYS_DIR/clients
TEMP_DIR=/tmp/certstore
NEW_CERTS_DIR=$ROOT/new_certs

NO_PASS=true # need to implement client pem password protection
EXPORT_AS=""
EXPORT_PASS=""
BATCH=

# Functions
print_help() {
	echo "-h, -help : this output"
	echo "-c n, -certs n : number of certs, n, to make"
    echo "-batch, to autoyes all prompts"
	exit 1	
}


# Parse Args
while [ $# -ne 0 ] 
do
	case $1 in 
		"-nopass")
			NO_PASS=true
		;;
		"-certs"|"-c")
			shift
			NUM_CERTS=$1
		;;
		"-help"|"-h")
			print_help
		;;
		"-export"|"-e")
			shift
			EXPORT_AS=$1
		;;
		"-exppass")
			shift
			EXPORT_PASS=$1
		;;
        "-batch")
            BATCH=-batch
        ;;
		*)
			echo "Invalid args."
			exit
		;;
	esac
	shift
done

# Check that the temp store has been created
if [ ! -d $TEMP_DIR ] ; then
	mkdir $TEMP_DIR
	chmod 600 $TEMP_DIR
fi 

CERTS_DONE=0
while [ $CERTS_DONE -ne $NUM_CERTS ] 
do

SERIAL_NUMBER=`cat $CA_ISSUE_DIR/serial.txt`
COMMON_NAME="$COMMON_NAME_PREFIX-$SERIAL_NUMBER"

# Copy the client.cnf to TEMP_DIR
echo "Updating client.cnf"
cp $CONFIG_DIR/client.cnf $TEMP_DIR/client.cnf

# Edit the temporary file
KEY_FILE=$CA_CLIENT_KEYS_DIR/$COMMON_NAME.pem
sed -i "/commonName_default/s|.*|commonName_default=$COMMON_NAME|" $TEMP_DIR/client.cnf
sed -i '/default_keyfile/s|.*|default_keyfile='$KEY_FILE'|' $TEMP_DIR/client.cnf

# Make a CSR for the client certicate
openssl req -new -config $TEMP_DIR/client.cnf -out "$TEMP_DIR/client_req.csr" -outform PEM $BATCH -nodes >/dev/null 2>&1

# Sign the CSRs
CERT_FILE=$COMMON_NAME'_cert.pem'
if [ $NO_PASS = false ] ; then
	openssl ca $BATCH -config $CONFIG_DIR/ca.cnf -passin file:$CA_DIR/ca.pp -policy signing_policy -extensions signing_req -out "$NEW_CERTS_DIR/$CERT_FILE" -in "$TEMP_DIR/client_req.csr" >/dev/null 2>&1
else
	openssl ca $BATCH -config $CONFIG_DIR/ca.cnf -policy signing_policy -extensions signing_req -out "$NEW_CERTS_DIR/$CERT_FILE" -in "$TEMP_DIR/client_req.csr" >/dev/null 2>&1
fi

if [ ! $EXPORT_AS = "" ] ; then
	if [ $EXPORT_PASS = "" ] ; then
		EXPORT_PASS="wifiwasp"
	fi
	openssl pkcs12 -export -in "$NEW_CERTS_DIR/$CERT_FILE" -inkey "$CA_CLIENT_KEYS_DIR/$COMMON_NAME.pem" -certfile "$CA_DIR/ca_cert.pem" -out "$NEW_CERTS_DIR/$COMMON_NAME.p12" -passout pass:$EXPORT_PASS
fi

rm -rf $NEW_CERTS_DIR/$SERIAL_NUMBER.pem

CERTS_DONE=$((CERTS_DONE+1))
done # while

echo "Done."