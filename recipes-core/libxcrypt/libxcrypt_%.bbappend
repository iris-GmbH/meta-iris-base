# Disable weak and deprecated hash functions in libcrypt
EXTRA_OECONF:append = " --enable-hashes=strong"
