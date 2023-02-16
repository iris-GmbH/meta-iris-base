# Generate "downloads" encryption key/cert for testing purposes

```bash
openssl genrsa -out download_snakeoil.key 4096
openssl req -new -x509 -key download_snakeoil.key -out download_snakeoil.crt -days 3650
```
