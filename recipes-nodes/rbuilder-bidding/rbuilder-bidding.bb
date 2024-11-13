DESCRIPTION = "Rbuilder bidding service"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI += "file://init"

INITSCRIPT_NAME = "rbuilder-bidding"
INITSCRIPT_PARAMS = "defaults 98"

inherit update-rc.d

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/rbuilder-bidding
}

FILES:${PN} = "${sysconfdir}/init.d/${INITSCRIPT_NAME}"
