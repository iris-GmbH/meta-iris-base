# rerun on each build to make sure the version is updated
do_compile[nostamp] = "1"
do_install[nostamp] = "1"

OS_RELEASE_FIELDS += "MACHINE"
