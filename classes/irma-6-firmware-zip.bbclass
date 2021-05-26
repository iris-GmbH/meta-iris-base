# SPDX-License-Identifier: MIT
# Copyright (C) 2021 iris-GmbH infrared & intelligent sensors

do_createfirmwarezip[depends] += "${PN}:do_image_complete"
do_createfirmwarezip[depends] += "virtual/kernel:do_deploy"
do_createfirmwarezip[depends] += "virtual/bootloader:do_deploy"
do_createfirmwarezip[nostamp] = "1"

DEPENDS += "python3-pyyaml-native"

python do_createfirmwarezip() {
    from zipfile import ZipFile
    import yaml
    import errno
    import tempfile

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

    def create_meta_and_zip(deployfiles, metatype, file_list):
        version_string_full = "{:s}-{:s}-{:s}-{:s}".format(metatype, d.getVar('PN', True), d.getVar('PV', True), d.getVar('IMAGE_NAME', True))
        version_string_short = "{:s}-{:s}".format(metatype, d.getVar('PN', True))

        # Create meta.yaml
        meta = {}
        meta[metatype] = {}
        for f in file_list:
            meta[metatype][f] = { 'file': os.path.basename(deployfiles[f]) }
        meta["version"] = version_string_full

        # Write meta.yaml to /tmp
        meta_temp = tempfile.NamedTemporaryFile(mode = "w")
        yaml.dump(meta, meta_temp.file)

        # Create ./update_files directory in deploy directory
        update_file_dir = os.path.join(deploy_dir, 'update_files')
        os.makedirs(update_file_dir, exist_ok=True)

        zip_full_name = "{:s}.zip".format(version_string_full)
        zip_link_name = "{:s}.zip".format(version_string_short)
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
