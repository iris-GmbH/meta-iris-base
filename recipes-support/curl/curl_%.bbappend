
# Disable NTLM on sc57x as we install a stripped down openssl library
EXTRA_OECONF:append:sc57x = " --disable-ntlm"

# enable ares - allows custom DNS server for vlair service with CURLOPT_DNS_SERVERS
# Disable the threaded resolver (not compatible with ares).
PACKAGECONFIG:remove:class-target = "threaded-resolver"
PACKAGECONFIG:append:class-target = " ares"
