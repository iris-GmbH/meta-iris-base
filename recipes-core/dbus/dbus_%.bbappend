PACKAGECONFIG:remove = "x11"

# remove tests and assertions
EXTRA_OECONF:remove = "--enable-tests"
EXTRA_OECONF:remove = "--enable-asserts"

# Set a fixed GID for the dbus-common group
GID="987"
GROUPADD_PARAM:dbus-common = " --gid ${GID} messagebus"
USERADD_PARAM:dbus-common:remove = "--user-group"
USERADD_PARAM:dbus-common:prepend = "--gid ${GID} --uid ${GID} "
