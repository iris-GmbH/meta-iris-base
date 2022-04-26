do_assemble_fit_prepend() {
	sed -i "s|ITS_KERNEL_LOAD_ADDR|0x40480000|g" ${B}/rescue.its.in
	sed -i "s|ITS_KERNEL_ENTRY_ADDR|0x40480000|g" ${B}/rescue.its.in
}
