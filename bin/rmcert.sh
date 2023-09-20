#!/bin/bash
#VERSION 1.1
# Exit immediately if a command exits with a non-zero status
set -e

#Variables
CERT_NAME=$1
EASY_RSA=/usr/share/easy-rsa
OPENVPN_DIR=/etc/openvpn
INDEX=$EASY_RSA/pki/index.txt
OVPN_FILE_PATH="$OPENVPN_DIR/clients/$CERT_NAME.ovpn"

# Check if .ovpn file exists
if [[ ! -f $OVPN_FILE_PATH ]]; then
    echo "User not found."
    exit 1
fi

# Define key serial number by keyname
# Fix for https://github.com/d3vilh/openvpn-ui/issues/5 by shuricksumy@github
STATUS_CH=$(grep -e ${CERT_NAME}$ -e${CERT_NAME}/ ${INDEX} | awk '{print $1}' | tr -d '\n')
if [[ $STATUS_CH = "V" ]]; then
    echo -e "Cert is VALID\nShould not remove: $CERT_NAME"
    CERT_SERIAL=$(grep ${CERT_NAME}/ ${INDEX} | awk '{print $3}' | tr -d '\n')
    echo "Valid Cert serial: $CERT_SERIAL"
else
    echo -e "Cert is REVOKED\nContinue to remove: $CERT_NAME"
    CERT_SERIAL=$(grep ${CERT_NAME}/ ${INDEX} | awk '{print $4}' | tr -d '\n')
    echo "Revoked Cert serial: $CERT_SERIAL"
fi

# Remove user from OpenVPN
rm -f /etc/openvpn/pki/certs_by_serial/$CERT_SERIAL.pem
rm -f /etc/openvpn/pki/issued/$CERT_NAME.crt
rm -f /etc/openvpn/pki/private/$CERT_NAME.key
rm -f /etc/openvpn/pki/reqs/$CERT_NAME.req
rm -f /etc/openvpn/clients/$CERT_NAME.ovpn

# Fix index.txt by removing the user from the list following the serial number
sed -i'.bak' "/${CERT_SERIAL}/d" $INDEX
echo "Database fixed."

echo -e "Remove done!\nIf you want to disconnect the user please restart the OpenVPN service or container."