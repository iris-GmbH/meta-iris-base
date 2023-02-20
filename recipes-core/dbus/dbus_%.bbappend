PACKAGECONFIG:remove = "x11"

# remove tests and assertions
EXTRA_OECONF:remove = "--enable-tests"
EXTRA_OECONF:remove = "--enable-asserts"
