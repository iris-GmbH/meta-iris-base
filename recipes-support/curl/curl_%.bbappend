
# Disable NTLM on sc57x as we install a stripped down openssl library
EXTRA_OECONF:append:sc57x = " --disable-ntlm"
