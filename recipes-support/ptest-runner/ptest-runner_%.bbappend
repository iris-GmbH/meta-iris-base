# Adding groups in Yocto is tricky. The irma-* recipes create their own groups with fixed GIDs so the file system
# can keep track of ownerships across updates. But having some packages with fixed GIDs and some with automatic GIDs
# can lead to problems during rootfs creation. When an automatic GID package is installed after a fixed GID package,
# it takes the fixed GID minus 1. If another fixed GID package is installed afterwards which tries to claim this GID,
# it will fail.
# ptest-runner had conflicts with nginx (fixed GIDs), as ptest-runner unknowingly took nginx GID. To work around this,
# we set fixed GIDs for ptest-runner as well.

GROUPADD_PARAM:${PN} = " --gid 920 ptest"
USERADD_PARAM:${PN}:remove = "--user-group"
USERADD_PARAM:${PN}:prepend = "--gid 920 --uid 920 "

