DESCRIPTION = "HAProxy"
LICENSE = "HAPROXY's license - 2006/06/15"
FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI += "file://init \
            file://haproxy.cfg.mustache"

INITSCRIPT_NAME = "haproxy"
INITSCRIPT_PARAMS = "defaults 98"

inherit update-rc.d

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -d -m 0755 ${D}${sysconfdir}/haproxy
    install -m 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/haproxy
    install -m 0644 ${THISDIR}/haproxy.cfg.mustache ${D}${sysconfdir}/haproxy/haproxy.cfg.mustache
}

FILES:${PN} = "${sysconfdir}/init.d/${INITSCRIPT_NAME} ${sysconfdir}/haproxy/haproxy.cfg.mustache"
