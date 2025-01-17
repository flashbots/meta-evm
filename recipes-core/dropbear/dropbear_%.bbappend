# Disable dropbear on all runlevels
INITSCRIPT_PARAMS = "stop 10 S ."
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://dropbear.default"

do_install:append() {
    install -d ${D}${sysconfdir}/default
    # override default poky dropbear configurations with local dropbear.default file
    install -m 0644 ${WORKDIR}/dropbear.default ${D}${sysconfdir}/default/dropbear

    # Ensure proper permissions on dropbear directory
    install -d ${D}${sysconfdir}/dropbear
    chmod 700 ${D}${sysconfdir}/dropbear
}

FILES:${PN} += "${sysconfdir}/default/dropbear"
