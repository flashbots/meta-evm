DESCRIPTION = "Syncs the reth state from a remote snapshot"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI += "file://init"
SRC_URI += "file://rclone.conf"

INITSCRIPT_NAME = "reth-sync"
INITSCRIPT_PARAMS = "defaults 96"

inherit update-rc.d useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-r -s /bin/false -U reth"

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/reth-sync
    install -m 0644 ${THISDIR}/rclone.conf ${D}${sysconfdir}/rclone.conf
    
    # Create directory for reth data
    install -d ${D}/persistent/reth
    chown reth:reth ${D}/persistent/reth
}

RDEPENDS:${PN} += "rclone"
FILES:${PN} += "/persistent/reth"
