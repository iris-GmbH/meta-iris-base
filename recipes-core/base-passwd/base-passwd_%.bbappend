FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# add add_i2c_gpio_userdata.patch, except for IRMA6 R1
I2C_GPIO_USERDATA_PATCH = "file://add_i2c_gpio_userdata.patch"
I2C_GPIO_USERDATA_PATCH:poky-iris-0601 = ""
SRC_URI:append = " ${I2C_GPIO_USERDATA_PATCH}"
