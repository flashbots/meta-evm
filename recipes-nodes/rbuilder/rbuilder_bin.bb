SUMMARY = "Rust Builder"
LICENSE = "CLOSED"


FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI += "file://rbuilder"
SRC_URI += "file://init"
SRC_URI += "file://config"
SRC_URI += "file://ofac.json"
S = "${WORKDIR}"

INITSCRIPT_NAME = "rbuilder"
INITSCRIPT_PARAMS = "defaults 99"

inherit update-rc.d

do_install() {
    install -d ${D}${bindir}
    install -m 0777 rbuilder ${D}${bindir}
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 init ${D}${sysconfdir}/init.d/rbuilder
    install -m 0755 config ${D}${sysconfdir}/rbuilder.config
    install -m 0755 ofac.json ${D}${sysconfdir}/rbuilder.ofac.json
}
RDEPENDS:${PN} += "reth cvm-reverse-proxy config-parser"
FILES_${PN} += "${bindir}"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"