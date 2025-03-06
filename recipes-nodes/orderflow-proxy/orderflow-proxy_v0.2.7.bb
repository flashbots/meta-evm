SUMMARY = "Orderflow Proxy"
HOMEPAGE = "https://github.com/flashbots/tdx-orderflow-proxy"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://src/${GO_WORKDIR}/LICENSE;md5=c7bc88e866836b5160340e6c3b1aaa10"

inherit go-mod update-rc.d

INITSCRIPT_NAME = "orderflow-proxy-init"
INITSCRIPT_PARAMS = "defaults 99"

GO_IMPORT = "github.com/flashbots/tdx-orderflow-proxy"
SRC_URI = "git://${GO_IMPORT};protocol=https;branch=main \
           file://orderflow-proxy-init \
           file://orderflow-proxy.conf.mustache"
SRCREV = "v0.2.7"

GO_INSTALL = "${GO_IMPORT}/cmd/receiver-proxy"
GO_LINKSHARED = ""

INHIBIT_PACKAGE_DEBUG_SPLIT = '1'
INHIBIT_PACKAGE_STRIP = '1'
GO_EXTRA_LDFLAGS:append = " -s -w -buildid= -X ${GO_IMPORT}/common.Version=${PV}"

do_compile[network] = "1"

do_compile() {
    cd ${S}/src/${GO_IMPORT}
    ${GO} build -trimpath -ldflags "${GO_EXTRA_LDFLAGS}" -o ${B}/receiver-proxy cmd/receiver-proxy/main.go
}

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/receiver-proxy ${D}${bindir}/orderflow-proxy

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/${INITSCRIPT_NAME} ${D}${sysconfdir}/init.d/${INITSCRIPT_NAME}
    install -m 0640 ${WORKDIR}/orderflow-proxy.conf.mustache ${D}${sysconfdir}/orderflow-proxy.conf.mustache
}

FILES:${PN} = "${sysconfdir}/init.d/${INITSCRIPT_NAME} ${bindir}/orderflow-proxy ${sysconfdir}/orderflow-proxy.conf.mustache"
