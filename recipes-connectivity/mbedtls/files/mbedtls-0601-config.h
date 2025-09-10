#ifndef MBEDTLS_CONFIG_H
#define MBEDTLS_CONFIG_H

#define MBEDTLS_PLATFORM_C
#define MBEDTLS_ERROR_C
#define MBEDTLS_FS_IO

/* ---------- Symmetric Encryption ---------- */
#define MBEDTLS_CIPHER_C
#define MBEDTLS_CIPHER_MODE_CBC
#define MBEDTLS_AES_C
#define MBEDTLS_MD_C
#define MBEDTLS_SHA256_C
#define MBEDTLS_SHA384_C
#define MBEDTLS_PKCS5_C
#define MBEDTLS_PSA_CRYPTO_C

/* ---------- Asymmetric Encryption ---------- */
#define MBEDTLS_RSA_C
#define MBEDTLS_PKCS1_V21
#define MBEDTLS_PK_C
#define MBEDTLS_PK_PARSE_C
#define MBEDTLS_PK_WRITE_C
#define MBEDTLS_PKCS8_C

/* ---------- ECC/ECDSA Support ---------- */
#define MBEDTLS_ECP_C
#define MBEDTLS_ECDSA_C
#define MBEDTLS_ECP_DP_SECP384R1_ENABLED

/* ---------- PSA Crypto Support ---------- */
#define PSA_WANT_ECC_SECP_R1_384  

/* ---------- ASN.1 and Encoding ---------- */
#define MBEDTLS_ASN1_PARSE_C
#define MBEDTLS_ASN1_WRITE_C
#define MBEDTLS_PEM_PARSE_C
#define MBEDTLS_BASE64_C
#define MBEDTLS_BIGNUM_C
#define MBEDTLS_OID_C

/* ---------- Random Number Generation ---------- */
#define MBEDTLS_ENTROPY_C
#define MBEDTLS_CTR_DRBG_C

/* ---------- Hash Functions ---------- */
#define MBEDTLS_SHA1_C

/* ---------- X.509 Support ---------- */
#define MBEDTLS_X509_CRT_PARSE_C
#define MBEDTLS_X509_USE_C

#include "mbedtls/check_config.h"

#endif /* MBEDTLS_CONFIG_H */
