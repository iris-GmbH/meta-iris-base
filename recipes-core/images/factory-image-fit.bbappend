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
