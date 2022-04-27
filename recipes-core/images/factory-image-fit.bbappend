FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

do_assemble_fit_prepend() {
	if [ -z "${FITLOADADDR}" ]; then
		FITLOADADDR=0x48000000
		bbwarn "Set FITLOADADDR to ${FITLOADADDR}"
	fi

	if [ -z "${RESCUE_NAME_FULL}" ]; then
		bbwarn "RESCUE_NAME_FULL is not set"
	fi

	if [ -z "${RESCUE_RUNNING_VERSION}" ]; then
		RESCUE_RUNNING_VERSION=0.0.0
		bbwarn "Set RESCUE_RUNNING_VERSION to ${RESCUE_RUNNING_VERSION}"
	fi

	if [ -z "${CRYPTO_HW_ACCEL}" ]; then
		bbwarn "CRYPTO_HW_ACCEL is not set"
	fi

	if [ -z "${SIGN_CERT}" ]; then
		bbwarn "SIGN_CERT is not set"
	fi

	if [ -z "${CSFK}" ]; then
		bbwarn "CSFK is not set"
	fi

	if [ -z "${SRKTAB}" ]; then
		bbwarn "SRKTAB is not set"
	fi

	sed -i "s|ITS_KERNEL_LOAD_ADDR|0x40480000|g" ${B}/rescue.its.in
	sed -i "s|ITS_KERNEL_ENTRY_ADDR|0x40480000|g" ${B}/rescue.its.in
}

# create fit Image
do_assemble_fit() {
	echo "STAGING_KERNEL_DIR" ${STAGING_KERNEL_DIR}
	echo "STAGING_KERNEL_BUILDDIR" ${STAGING_KERNEL_BUILDDIR}
	echo "KERNEL_SRC_PATH" ${KERNEL_SRC_PATH}
	export DEPLOY_DIR_IMAGE=${DEPLOY_DIR_IMAGE}
	export KERNEL_DEVICETREE=${KERNEL_DEVICETREE}
	export RESCUE_NAME_FULL=${RESCUE_NAME_FULL}
	export RESCUE_RUNNING_VERSION=${RESCUE_RUNNING_VERSION}
	export MACHINE=${MACHINE}
	export KERNEL_IMAGETYPE=${KERNEL_IMAGETYPE}
	if [ "${TARGET_ARCH}" = "aarch64" ]; then
		export TARGET_ARCH=arm64
	else
		export TARGET_ARCH=${TARGET_ARCH}
	fi
	echo "B" ${B}
	echo "S" ${S}
	echo $DEPLOY_DIR_IMAGE
	echo "FNAME " ${ITB_FNAME}
	cd ${B}
	cp ${B}/rescue.its.in ${B}/rescue.its
	sed -i "s|DEPLOY_DIR_IMAGE|$DEPLOY_DIR_IMAGE|g" rescue.its
	sed -i "s|RESCUE_NAME_FULL|$RESCUE_NAME_FULL|g" rescue.its
	sed -i "s|RESCUE_RUNNING_VERSION|$RESCUE_RUNNING_VERSION|g" rescue.its
	sed -i "s|MACHINE|$MACHINE|g" rescue.its
	sed -i "s|TARGET_ARCH|$TARGET_ARCH|g" rescue.its
	sed -i "s|KERNEL_IMAGETYPE|$KERNEL_IMAGETYPE|g" rescue.its
	sed -i "s|KERNEL_DEVICETREE|$(basename $KERNEL_DEVICETREE)|g" rescue.its
	cat rescue.its
	echo "======== create itb file ==========="
	uboot-mkimage -D "-I dts -O dtb -p 0x1000" -f rescue.its ${ITB_FNAME}
		if [ $? -ne 0 ]; then
		echo create FIT image failed
		exit 1
	fi

	install -d ${DEPLOY_DIR_IMAGE}
	install -m 644 ${ITB_FNAME} ${DEPLOY_DIR_IMAGE}/${ITB_FNAME}

	prepare_hab_image ${ITB_FNAME}
	install ${ITB_FNAME}-ivt.${KERNEL_SIGN_SUFFIX} ${DEPLOY_DIR_IMAGE}/${ITB_FNAME}.${KERNEL_SIGN_SUFFIX}
}

#
# Emit the CSF File
#
# $1 ... .csf filename
# $2 ... SRK Table Binary
# $3 ... CSF Key File
# $4 ... Image Key File
# $5 ... Blocks Parameter
# $6 ... Image File
# $7 ... Crypto engine
csf_emit_file() {
	cat << EOF > ${1}
[Header]
Version = 4.5
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS
Engine = ${7}

[Install SRK]
File = "${2}"
Source index = 0

[Install CSFK]
File = "${3}"

[Authenticate CSF]

[Install Key]
Verification index = 0
Target Index = 2
File= "${4}"

[Authenticate Data]
Verification index = 2
Blocks = ${5} "${6}"

[Unlock]
Engine = ${7}
Features = RNG
EOF
}
