DESCRIPTION = "syncs the reth state from AWS s3"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI += "file://init"
SRC_URI += "file://rclone.conf"

INITSCRIPT_NAME = "reth-sync"
INITSCRIPT_PARAMS = "defaults 96"

inherit update-rc.d

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/reth-sync
    install -m 0644 ${THISDIR}/rclone.conf ${D}${sysconfdir}/rclone.conf
}

RDEPENDS:${PN} += "rclone"
