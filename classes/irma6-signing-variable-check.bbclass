# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

do_signing_variable_check() {
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
}
