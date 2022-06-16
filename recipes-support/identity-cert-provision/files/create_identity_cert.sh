#!/usr/bin/env bash

set -e
set -o pipefail

if [ $# -lt 3 ]; then
	echo "Usage: $0 PRODUCT_FAMILY SERIAL_NUMBER FILE_DIR"
	exit 1;
fi

if [ -z $SSL_CONFIG_FILE ]; then
    SSL_CONFIG_FILE="/etc/openssl/sensor_cert.cnf"
fi

# TODO: migrate openssl commands to utilize ecc
echo "Creating key pair..."
openssl ecparam -name secp521r1 -genkey -noout -out "$3/sensor.key"
openssl ec -in "$3/sensor.key" -pubout -out "$3/public.pem"

echo "Creating certificate signing request..."
PRODUCT_FAMILY=$1 SENSOR_SERIAL=$2 openssl req -new -nodes -key "$3/sensor.key" -out "$3/sensor.csr" -config "${SSL_CONFIG_FILE}"

