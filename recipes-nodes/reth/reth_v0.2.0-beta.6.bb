include reth.inc

FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI = "git://github.com/paradigmxyz/reth;protocol=https;branch=main"
SRC_URI += "file://libffi.patch"
SRCREV = "v0.2.0-beta.6"

DEPENDS += " libffi"
RDEPENDS:${PN} += "libffi"
