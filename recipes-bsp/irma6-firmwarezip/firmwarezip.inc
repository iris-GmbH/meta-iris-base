# SPDX-License-Identifier: MIT
# Copyright (C) 2022 iris-GmbH infrared & intelligent sensors

IMAGENAME = "${@ d.getVar('PN').replace('-firmwarezip','')}"
inherit deploy

# Depend on image (read from PN), kernel and bootloader (u-boot)
do_install[depends] = "\
	${IMAGENAME}:do_image_complete \
	virtual/bootloader:do_deploy \
	virtual/kernel:do_deploy \
"
# get u-boot files to sysroot (/usr/share/uboot.release)
DEPENDS = "virtual/bootloader"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS += " python3-pyyaml-native"

# skip tasks, as we only want to deploy things
do_configure[noexec] = "1"
do_install[noexec] = "1"
do_compile[noexec] = "1"
do_deploy[nostamp] = "1"

# set generic file names that should match for most images
ROOTFSTYPE = "jffs2.sum"
FIRMWAREZIP_KERNEL_NAME = "uImage-gzip-${MACHINE}.bin"
FIRMWAREZIP_DEVTREE_NAME = "${MACHINE}.dtb"
FIRMWAREZIP_ROOTFS_NAME = "${IMAGENAME}-${MACHINE}-*.rootfs.${ROOTFSTYPE}"
FIRMWAREZIP_IMAGEMETA = "${IMAGENAME}-${MACHINE}-*.testdata.json"
FIRMWAREZIP_BOOTLOADER_NAME = "u-boot-${MACHINE}.ldr"
FIRMWAREZIP_BOOTLOADER_VERSION = "${STAGING_DATADIR}/uboot.release"

# set output directory and file names
FIRMWAREZIP_DEPLOY_DIR = "${DEPLOYDIR}/${PN}"

# Assert: Check if "firmwarezip" is in UPDATE_PROCEDURE or raise an SkipRecipe error
python() {
    if "firmwarezip" not in (d.getVar('UPDATE_PROCEDURE') or ""):
        raise bb.parse.SkipRecipe('firmwarezip images can only be build for machines that use this UPDATE_PROCEDURE')
}

python do_deploy() {
    from zipfile import ZipFile
    import yaml
    import json
    import glob
    import errno
    import tempfile

    # setup names and directories
    pn = d.getVar('IMAGENAME', True)
    image_dir = d.getVar('DEPLOY_DIR_IMAGE', True)
    deploy_dir = d.getVar('FIRMWAREZIP_DEPLOY_DIR', True)

    # transform wildcard name of rootfs and imagemeta to real filename
    l_imagemeta = glob.glob(os.path.join(image_dir, d.getVar('FIRMWAREZIP_IMAGEMETA')))
    l_rootfsname = glob.glob(os.path.join(image_dir, d.getVar('FIRMWAREZIP_ROOTFS_NAME')))
    assert(len(l_imagemeta) == 1 and len(l_rootfsname) == 1)

    imagemeta = json.load(open(l_imagemeta[0]))

    def get_fullpath(basepath, filepath):
        fullpath = os.path.join(basepath, filepath)
        realpath = os.path.realpath(fullpath)
        if not os.path.isfile(realpath):
            raise Exception("{:s} is not a file".format(filepath))
        return realpath

    def collect_files():
        deployfiles = {}
        deployfiles['kernel']  = get_fullpath(image_dir, d.getVar('FIRMWAREZIP_KERNEL_NAME'))
        deployfiles['devtree'] = get_fullpath(image_dir, d.getVar('FIRMWAREZIP_DEVTREE_NAME'))
        deployfiles['rootfs']  = get_fullpath(image_dir, l_rootfsname[0])
        deployfiles['u-boot']  = get_fullpath(image_dir, d.getVar('FIRMWAREZIP_BOOTLOADER_NAME'))
        return deployfiles

    def create_meta_and_zip(deployfiles, metatype, file_list):
        version_string = imagemeta['FIRMWARE_VERSION']

        # Create meta.yaml
        meta = {}
        meta[metatype] = {}
        for f in file_list:
            meta[metatype][f] = { 'file': os.path.basename(deployfiles[f]) }
        meta["version"] = version_string
        # additionally, add the bootloader versioning to the meta.yml file
        if metatype == "bootloader":
            with open(d.getVar('FIRMWAREZIP_BOOTLOADER_VERSION', True),'r') as f:
                bootloader_version = f.readline().rstrip()
            meta["bootloader-version"] = bootloader_version

        # Write meta.yaml to /tmp
        meta_temp = tempfile.NamedTemporaryFile(mode = "w")
        yaml.dump(meta, meta_temp.file)

        # Create deploy directory in work directory, clean it
        os.makedirs(deploy_dir, exist_ok=True)

        zip_full_name = "{:s}-{:s}.zip".format(metatype, version_string)
        # link is necessary, so that we can identify and delete old build artifacts
        zip_link_name = "{:s}-{:s}.zip".format(metatype, pn)
        zip_path = os.path.join(deploy_dir, zip_full_name)
        zip_link = os.path.join(deploy_dir, zip_link_name)

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

addtask do_deploy after do_install
