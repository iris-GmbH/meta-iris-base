# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors
#
#
# This class archives all necessary components into a release zip file
#
# The following variables must be defined in machine- / local- / multiconfig:
# - FLASH_FSTYPE
# - FIRMWARE_ZIP_KERNEL_NAME
# - FIRMWARE_ZIP_DEVTREE_NAME
# - FIRMWARE_ZIP_BOOTLOADER_NAME
# - IMAGE_LINK_NAME
#
# For some targets it can be useful to skip this class (e.g. qemu).
# In this case set the variable SKIP_FIRMWARE_ZIP to "1" in the multiconfig

do_createfirmwarezip[depends] += "${PN}:do_image_complete"
do_createfirmwarezip[depends] += "virtual/kernel:do_deploy"
do_createfirmwarezip[depends] += "virtual/bootloader:do_deploy"
# we need the sysroot to access u-boot versioning file
do_createfirmwarezip[deptask] += "do_populate_sysroot"
do_createfirmwarezip[nostamp] = "1"

DEPENDS += "python3-pyyaml-native"

python do_createfirmwarezip() {
    from zipfile import ZipFile
    import yaml
    import errno
    import tempfile
    import re

    if "firmwarezip" not in (d.getVar('UPDATE_PROCEDURE', '') or ""):
        return

    if d.getVar('SKIP_FIRMWARE_ZIP', True) == "1":
        return

    pn = d.getVar('PN', True)
    deploy_dir = d.getVar('DEPLOY_DIR_IMAGE', True)
    work_dir = os.path.join(d.getVar('WORKDIR', True), "deploy-{:s}-image-complete".format(pn))

    def select_file(override_var, default_var='', default_str=''):
        file_name = d.getVar(override_var, True)
        if file_name == None:
            file_name = d.getVar(default_var, True)
        if file_name == None:
            file_name = default_str
        return file_name

    def get_fullpath(basepath, filepath):
        fullpath = os.path.join(basepath, filepath)
        realpath = os.path.realpath(fullpath)
        if not os.path.isfile(realpath):
            raise Exception("{:s} is not a file".format(filepath))
        return realpath

    def collect_files():
        deployfiles = {}
        deployfiles['kernel']  = get_fullpath(deploy_dir, select_file('FIRMWARE_ZIP_KERNEL_NAME',  'KERNEL_IMAGETYPE'))
        deployfiles['devtree'] = get_fullpath(deploy_dir, select_file('FIRMWARE_ZIP_DEVTREE_NAME', 'KERNEL_DEVICETREE'))
        rootfs_link_name = "{:s}.{:s}".format(d.getVar('IMAGE_LINK_NAME', True), d.getVar('FLASH_FSTYPE', True))
        deployfiles['rootfs']  = get_fullpath(work_dir, select_file('FIRMWARE_ZIP_ROOTFS_NAME', default_str=rootfs_link_name))
        deployfiles['u-boot']  = get_fullpath(deploy_dir, select_file('FIRMWARE_ZIP_BOOTLOADER_NAME', 'UBOOT_SYMLINK'))
        return deployfiles

    def version_workaround(version_string):
        version_matches = re.match(r"^(.*)-(\d+\.\d+)(-.*)$", version_string)
        prefix = version_matches.group(1)
        version = version_matches.group(2)
        suffix = version_matches.group(3)
        return f"{prefix}-{version}.0{suffix}"

    def create_meta_and_zip(deployfiles, metatype, file_list):
        version_string = d.getVar('FIRMWARE_VERSION', True)

        # Create meta.yaml
        meta = {}
        meta[metatype] = {}
        for f in file_list:
            meta[metatype][f] = { 'file': os.path.basename(deployfiles[f]) }
        meta["version"] = version_workaround(version_string)
        # additionally, add the bootloader versioning to the meta.yml file
        if metatype == "bootloader":
            with open(d.getVar('STAGING_DIR_HOST', True) + d.getVar('datadir', True) + '/uboot.release','r') as f:
                bootloader_version = f.readline().rstrip()
            meta["bootloader-version"] = bootloader_version

        # Write meta.yaml to /tmp
        meta_temp = tempfile.NamedTemporaryFile(mode = "w")
        yaml.dump(meta, meta_temp.file)

        # Create ./update_files directory in deploy directory
        update_file_dir = os.path.join(deploy_dir, 'update_files')
        os.makedirs(update_file_dir, exist_ok=True)

        zip_full_name = "{:s}-{:s}.zip".format(metatype, version_string)
        # link is necessary, so that we can identify and delete old build artifacts
        zip_link_name = "{:s}-{:s}.zip".format(metatype, d.getVar('PN', True))
        zip_path = os.path.join(update_file_dir, zip_full_name)
        zip_link = os.path.join(update_file_dir, zip_link_name)

        # Remove old artifacts
        try:
            os.remove(os.path.realpath(zip_link))
            os.remove(zip_link)
        except OSError as e:
            if e.errno != errno.ENOENT: # errno.ENOENT = no such file or directory
                raise

        # Create zip file and symlink
        with ZipFile(zip_path, 'w') as z:
            for f in file_list:
                z.write(deployfiles[f], meta[metatype][f]['file'])
            z.write(meta_temp.name, 'meta.yaml')

        os.symlink(os.path.basename(zip_path), zip_link)

    deployfiles = collect_files()
    create_meta_and_zip(deployfiles, 'firmware', ['kernel', 'devtree', 'rootfs'])
    create_meta_and_zip(deployfiles, 'bootloader', ['u-boot'])
}

addtask createfirmwarezip after do_rootfs before do_build
