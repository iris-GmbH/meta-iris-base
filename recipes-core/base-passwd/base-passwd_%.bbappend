FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# only for IRMA6R2 and Matrix
SRC_URI:append:poky-iris-0602 = "file://add_i2c_gpio_userdata.patch"
SRC_URI:append:poky-iris-0501 = "file://add_i2c_gpio_userdata.patch"
