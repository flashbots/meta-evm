DESCRIPTION = "HAProxy is a free, very fast and reliable solution offering high availability, load balancing for TCP and HTTP-based applications"
HOMEPAGE = "https://www.haproxy.org/"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE;md5=2d862e836f92129cdc0ecccc54eed5e0"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI += "file://init \
            file://LICENSE \
            file://haproxy.cfg.mustache \
            file://index.html"

INITSCRIPT_NAME = "haproxy"
INITSCRIPT_PARAMS = "defaults 90"

inherit update-rc.d

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -d -m 0755 ${D}${sysconfdir}/haproxy/certs ${D}${sysconfdir}/haproxy/static
    install -m 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/haproxy
    install -m 0644 ${THISDIR}/haproxy.cfg.mustache ${D}${sysconfdir}/haproxy/haproxy.cfg.mustache
    install -m 0644 ${THISDIR}/index.html ${D}${sysconfdir}/haproxy/static/index.html
}

FILES:${PN} = "${sysconfdir}/init.d/${INITSCRIPT_NAME} \
               ${sysconfdir}/haproxy/certs \
               ${sysconfdir}/haproxy/haproxy.cfg.mustache \
               ${sysconfdir}/haproxy/static/index.html"
