# How to create the Diffie–Hellman Parameters for nginx TLS key exchange?

- see https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1k&hsts=false&ocsp=false&guideline=5.6
- see https://support.count.ly/hc/en-us/articles/360037816431-Configuring-HTTPS-and-SSL

```bash
$ openssl dhparam -outform pem -out dhparam2048.pem 2048
```
