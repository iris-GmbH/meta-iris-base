### Service CA
Used for vlair alpha identity verification. Retrieved from public iris vault:
```bash
export VAULT_ADDR=https://vault.prod.defra01.iris-sensing.net
curl -sS "$VAULT_ADDR/v1/iris/vlair-alpha/pki/alpha/service-identity/ca/pem" -o alpha-service-identity-ca.pem
```
