# Some size optimizations for R1
# 10,28MB now vs 10,5MB without rootfs.jffs2
EXTRA_OECONF_append_sc57x = " no-deprecated no-err no-filenames no-ocsp no-ui-console no-srp no-ct no-dtls"
CFLAGS_append_sc57x = " -Os"
CXXFLAGS_append_sc57x = " -Os"

