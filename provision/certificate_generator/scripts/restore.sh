#!/bin/bash

read -p "Executing this script will restore /certstore to default settings. Continue [N/y]?" CONTINUE

CONTINUE=${CONTINUE:-"n"}
CONTINUE=$(echo "$CONTINUE" | awk '{print tolower($CONTINUE)}')

case $CONTINUE in 
	"y")
		echo "Running restore..."
	;;
	"n")
		echo "Restore cancelled."
		exit 1
	;;
	*)
		echo "Invalid argument ($CONITNUE)."
		exit 0
	;;
esac

CERTSTORE_DIR=`pwd`

echo "Removing directories..."

rm -rf $CERTSTORE_DIR/CA
rm -rf $CERTSTORE_DIR/certs
rm -rf $CERTSTORE_DIR/new_certs

echo "Updating config files to include current working directory location..."

sed -i "1 s|.*|ROOT=$CERTSTORE_DIR|" $CERTSTORE_DIR/configs/ca.cnf
sed -i "1 s|.*|ROOT=$CERTSTORE_DIR|" $CERTSTORE_DIR/configs/server.cnf
sed -i "1 s|.*|ROOT=$CERTSTORE_DIR|" $CERTSTORE_DIR/configs/client.cnf

echo "Certstore restored."