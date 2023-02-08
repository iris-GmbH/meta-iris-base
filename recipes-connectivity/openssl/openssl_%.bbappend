# Size optimizations for R1
EXTRA_OECONF:append:sc57x = " no-deprecated no-err no-filenames no-ocsp no-ui-console no-srp no-ct no-dtls"
CFLAGS:append:sc57x = " -Os"
CXXFLAGS:append:sc57x = " -Os"
