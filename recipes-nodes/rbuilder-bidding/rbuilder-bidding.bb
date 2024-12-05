DESCRIPTION = "Rbuilder bidding service"
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI += "file://init \
            file://rbuilder-bidding-token.mustache \
            file://bidding-service.toml.mustache"

INITSCRIPT_NAME = "rbuilder-bidding"
INITSCRIPT_PARAMS = "defaults 98"

inherit update-rc.d useradd

DEPENDS += "eth-group"
RDEPENDS:${PN} += "eth-group"

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-r -s /bin/false -G eth rbuilder"

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -d -m 0755 ${D}${sysconfdir}/rbuilder-bidding
    install -m 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/rbuilder-bidding
    install -m 0600 ${THISDIR}/bidding-service.toml.mustache ${D}${sysconfdir}/rbuilder-bidding/bidding-service.toml.mustache
    install -m 0600 ${THISDIR}/rbuilder-bidding-token.mustache ${D}${sysconfdir}/rbuilder-bidding/rbuilder-bidding-token.mustache
    chown -R rbuilder:rbuilder ${D}${sysconfdir}/rbuilder-bidding/*
}

FILES:${PN} = "${sysconfdir}/init.d/${INITSCRIPT_NAME} ${sysconfdir}/rbuilder-bidding/rbuilder-bidding-token.mustache ${sysconfdir}/rbuilder-bidding/bidding-service.toml.mustache"
