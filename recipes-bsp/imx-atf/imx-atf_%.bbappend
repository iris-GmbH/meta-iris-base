# Use BL31 version 2.4 from Meta-Freescale Hardknott release
# https://github.com/Freescale/meta-freescale/blob/hardknott/recipes-bsp/imx-atf/imx-atf_2.4.bb

SRCBRANCH = "lf_v2.4"
SRC_URI = "git://github.com/nxp-imx/imx-atf.git;protocol=https;branch=${SRCBRANCH}"
SRCREV = "ec35fef92b71a79075f214f8cff0738cd4482ed0"
