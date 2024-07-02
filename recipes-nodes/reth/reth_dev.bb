include reth.inc

SRC_URI = "git://github.com/paradigmxyz/reth;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

CARGO_BUILD_PROFILE = "profiling"
