SUMMARY = "Autoprovisioning Agent"
HOMEPAGE = "https://github.com/ruteri/tee-service-provisioning-backend"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://src/${GO_WORKDIR}/LICENSE;md5=c7bc88e866836b5160340e6c3b1aaa10"

inherit go-mod update-rc.d

INITSCRIPT_NAME = "autoprovisioning-agent-init"
INITSCRIPT_PARAMS = "defaults 87"

GO_IMPORT = "github.com/ruteri/tee-service-provisioning-backend"
SRC_URI = "git://${GO_IMPORT};protocol=https;branch=main \
           file://autoprovisioning-agent-init \
           file://autoprovisioning-agent.conf.mustache"
SRCREV = "v0.0.1"

GO_INSTALL = "${GO_IMPORT}/instanceutils/autoprovision"
GO_LINKSHARED = ""

INHIBIT_PACKAGE_DEBUG_SPLIT = '1'
INHIBIT_PACKAGE_STRIP = '1'
GO_EXTRA_LDFLAGS:append = " -s -w -buildid= -X ${GO_IMPORT}/common.Version=${PV}"

do_compile[network] = "1"

do_compile() {
    cd ${S}/src/${GO_IMPORT}
    ${GO} build -trimpath -ldflags "${GO_EXTRA_LDFLAGS}" -o ${B}/autoprovisioning-agent instanceutils/autoprovision/main.go
}

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/autoprovisioning-agent ${D}${bindir}/autoprovisioning-agent

    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/${INITSCRIPT_NAME} ${D}${sysconfdir}/init.d/${INITSCRIPT_NAME}
    install -m 0640 ${WORKDIR}/autoprovisioning-agent.conf.mustache ${D}${sysconfdir}/autoprovisioning-agent.conf.mustache
}

FILES:${PN} = "${sysconfdir}/init.d/${INITSCRIPT_NAME} ${bindir}/autoprovisioning-agent ${sysconfdir}/autoprovisioning-agent.conf.mustache"
