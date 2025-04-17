# How to create pki with ca/crt/key?

## Requirements
- Package: easy-rsa

## Create PKI
```bash
$ export EASYRSA=$(pwd)/certs
$ easyrsa init-pki
$ easyrsa build-ca
# Enter New CA Key Passphrase: hallo00 [Enter]
# Re-Enter New CA Key Passphrase: hallo00 [Enter]
# Common Name: [Enter]
$ easyrsa --subject-alt-name="DNS:irma6-DEV,IP.1:192.168.240.254,IP.2:172.16.0.10,IP.3:10.42.0.70" gen-req sensor nopass
# Common Name: [Enter]
$ easyrsa --days=7300 --subject-alt-name="DNS:irma6-DEV,IP.1:192.168.240.254,IP.2:172.16.0.10,IP.3:10.42.0.70" sign-req server sensor
$ ln -s certs/pki/ca.crt ca_identity_snakeoil.crt
$ ln -s certs/pki/issued/sensor.crt sensor_identity_snakeoil.crt
$ ln -s certs/pki/private/sensor.key sensor_identity_snakeoil.key

$ tree certs
certs
└── pki
    ├── ca.crt                                     <-- ca_identity_snakeoil.crt
    ├── certs_by_serial
    │   └── FE7E626D1BAA54E5897F9CD03824E38B.pem
    ├── index.txt
    ├── index.txt.attr
    ├── index.txt.attr.old
    ├── index.txt.old
    ├── issued
    │   └── sensor.crt                             <-- sensor_identity_snakeoil.crt
    ├── openssl-easyrsa.cnf
    ├── private
    │   ├── ca.key
    │   └── sensor.key                             <-- sensor_identity_snakeoil.key
    ├── reqs
    │   └── sensor.req
    ├── revoked
    │   ├── certs_by_serial
    │   ├── private_by_serial
    │   └── reqs_by_serial
    ├── safessl-easyrsa.cnf
    ├── serial
    └── serial.old
```


