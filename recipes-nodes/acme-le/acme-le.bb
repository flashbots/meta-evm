DESCRIPTION = "A pure Unix shell script implementing ACME client protocol "
HOMEPAGE = "https://github.com/acmesh-official/acme.sh"
LICENSE = "GPL-3.0"
LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI = "git://github.com/acmesh-official/acme.sh;protocol=https;branch=master"
SRCREV = "42bbd1b44af48a5accce07fa51740644b1c5f0a0"

SRC_URI += "file://acme-le.cron \
            file://LICENSE \
            file://acme-le.env.mustache \
            file://acme-le.sh"

INITSCRIPT_NAME = "acme-le"
INITSCRIPT_PARAMS = "defaults 91"

inherit update-rc.d

DEPENDS += "haproxy"
RDEPENDS:${PN} += "haproxy"

do_install() {
  install -d ${D}${sysconfdir}/init.d
  install -d -m 0755 ${D}${sysconfdir}/acme.sh
  install -m 0755 ${WORKDIR}/deploy/haproxy.sh ${D}${sysconfdir}/acme.sh/deploy/haproxy.sh
  install -m 0755 ${WORKDIR}/acme.sh ${D}${bindir}/acme.sh
  install -m 0755 ${WORKDIR}/acme-le.sh ${D}${sysconfdir}/init.d/acme-le
  install -m 0644 ${THISDIR}/acme-le.env.mustache ${D}${sysconfdir}/acme.sh/acme-le.env.mustache
  install -m 0640 ${WORKDIR}/acme-le.cron ${D}${sysconfdir}/cron.d/acme-le.cron
}

FILES:${PN} = "${D}${sysconfdir}/acme.sh/deploy/haproxy.sh \
               ${D}${bindir}/acme.sh \
               ${sysconfdir}/init.d/${INITSCRIPT_NAME} \
               ${D}${sysconfdir}/acme.sh/acme-le.env.mustache \
               ${D}${sysconfdir}/cron.d/acme-le.cron"
