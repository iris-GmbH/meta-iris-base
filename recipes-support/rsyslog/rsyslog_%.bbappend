# recipe to change configuration for remote syslog server und starting up


target_path_syslog_file = "/etc/init.d/"
target_path_syslog_startup_file = "/etc/"

do_install_append() {
    if [ ! -d ${target_path_syslog_file} ] && [! -d ${target_path}]; then
		install -d ${D}/${target_path_syslog_file}
		install -d ${D}/${target_path_syslog_startup_file}
	fi

	#copy syslog file and syslog-starup file for remote syslog server configuration
	install -m 0755 ${WORKDIR}/syslog ${D}/${target_path_syslog_file}
	install -m 0755 ${WORKDIR}/syslog-startup.conf ${D}/${target_path_syslog_startup_file}

}
