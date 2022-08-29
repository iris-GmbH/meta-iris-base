# How to create crt/csr/key?

```bash
# Create sensor.key, sensor.csr and public.pem with pvsn_create_identity_cert.sh or the following:
$ SSL_CONFIG_FILE="pvsn_create_identity_cert.cnf"
$ openssl ecparam -name secp384r1 -genkey -noout -out sensor_identity_snakeoil.key
$ openssl ec -in sensor_identity_snakeoil.key -pubout -out sensor_identity_snakeoil.pubkey
$ PRODUCT_FAMILY=irma6R2 SENSOR_SERIAL=9900010001 openssl req -new -nodes -key sensor_identity_snakeoil.key -out sensor_identity_snakeoil.csr -config "${SSL_CONFIG_FILE}"

# Create self signing crt
$ openssl x509 -signkey sensor_identity_snakeoil.key -in sensor.csr -req -days 7300 -out sensor_identity_snakeoil.crt
```


