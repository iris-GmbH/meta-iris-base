# Size optimizations for R1
EXTRA_OECONF:append:sc57x = " no-asm no-zlib no-rc2 no-idea no-des no-bf no-cast no-md2 no-mdc2 no-rc5 no-camellia no-seed no-err no-filenames no-ocsp no-ui-console no-srp no-ct no-dtls"
CFLAGS:append:sc57x = " -Os"
CXXFLAGS:append:sc57x = " -Os"
