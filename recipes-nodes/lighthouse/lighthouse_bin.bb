SUMMARY = "Lighthouse"
DESCRIPTION = "Consensus client to run on the side with the execution client"
HOMEPAGE = "https://lighthouse.sigmaprime.io/"
LICENSE="CLOSED"
LIC_FILES_CHKSUM=""


FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI += "file://lighthouse"
SRC_URI += "file://init"
S = "${WORKDIR}"

INITSCRIPT_NAME = "lighthouse"
INITSCRIPT_PARAMS = "defaults 97"

inherit update-rc.d

do_install() {
    install -d ${D}${bindir}
    install -m 0777 lighthouse ${D}${bindir}
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 init ${D}${sysconfdir}/init.d/lighthouse
}
#RDEPENDS:${PN} += "reth cvm-reverse-proxy config-parser"
FILES_${PN} += "${bindir}"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"