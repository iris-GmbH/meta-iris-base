# Test Certificate x509 / RSA 4096 key pair

```bash
openssl genrsa -out download_snakeoil.key 4096
openssl rsa -in download_snakeoil.key -pubout -out download_snakeoil_pub.key
openssl req -new -x509 -key download_snakeoil.key -out download_snakeoil.crt -days 3650
```
