# How to create crt/csr/key?

```bash
$ export EASYRSA=$(pwd)/certs
$ easyrsa init-pki
$ easyrsa build-ca
$ easyrsa --subject-alt-name="DNS:irma6-1234,IP:10.42.0.70" gen-req sensor nopass
$ easyrsa sign-req server sensor
```


