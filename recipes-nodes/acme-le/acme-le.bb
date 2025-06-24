DESCRIPTION = "A pure Unix shell script implementing ACME client protocol "
HOMEPAGE = "https://github.com/acmesh-official/acme.sh"
LICENSE = "GPL-3.0"
LIC_FILES_CHKSUM = "file://${WORKDIR}/LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI = "git://github.com/acmesh-official/acme.sh;protocol=https;branch=master"
SRCREV = "42bbd1b44af48a5accce07fa51740644b1c5f0a0"
S = "${WORKDIR}/git"

SRC_URI += "file://acme-le.cron \
            file://LICENSE \
            file://acme-le.env.mustache \
            file://acme-le.sh \
            file://post-hook.sh \
            file://haproxy-deploy-hook.patch"

INITSCRIPT_NAME = "acme-le"
INITSCRIPT_PARAMS = "defaults 91"

inherit update-rc.d

DEPENDS += " haproxy"
RDEPENDS:${PN} += " haproxy socat"

do_install() {
  install -d ${D}${sysconfdir}/init.d ${D}${bindir} ${D}${sysconfdir}/cron.d
  install -d -m 0755 ${D}${bindir}/acme.sh/deploy ${D}${bindir}/acme.sh/dnsapi ${D}${sysconfdir}/acme.sh/hooks
  install -m 0755 ${S}/deploy/haproxy.sh ${D}${bindir}/deploy/haproxy.sh
  install -m 0755 ${S}/dnsapi/dns_cf.sh ${D}${bindir}/dnsapi/dns_cf.sh
  install -m 0755 ${S}/acme.sh ${D}${bindir}/acme.sh
  install -m 0755 ${WORKDIR}/post-hook.sh ${D}${sysconfdir}/acme.sh/hooks/post-hook.sh
  install -m 0755 ${WORKDIR}/acme-le.sh ${D}${sysconfdir}/init.d/acme-le
  install -m 0644 ${WORKDIR}/acme-le.env.mustache ${D}${sysconfdir}/acme.sh/acme-le.env.mustache
  install -m 0640 ${WORKDIR}/acme-le.cron ${D}${sysconfdir}/cron.d/acme-le
}

FILES:${PN} = "${bindir}/acme.sh/deploy/haproxy.sh \
               ${bindir}/acme.sh/dnsapi/dns_cf.sh \
               ${sysconfdir}/acme.sh/hooks/post-hook.sh \
               ${bindir}/acme.sh \
               ${sysconfdir}/init.d/${INITSCRIPT_NAME} \
               ${sysconfdir}/acme.sh/acme-le.env.mustache \
               ${sysconfdir}/cron.d/acme-le"
