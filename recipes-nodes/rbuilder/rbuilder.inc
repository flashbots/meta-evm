SUMMARY = "Rust Builder"
DESCRIPTION = "Rust builder running with a full ethereum node (reth) implemented in rust."
LICENSE="CLOSED"
LIC_FILES_CHKSUM=""

inherit cargo_bin update-rc.d useradd

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

DEPENDS += "libffi openssl eth-group"
RDEPENDS:${PN} += "libffi openssl eth-group reth cvm-reverse-proxy-server cvm-reverse-proxy-client render-config"

export BINDGEN_EXTRA_CLANG_ARGS
BINDGEN_EXTRA_CLANG_ARGS = "--sysroot=${WORKDIR}/recipe-sysroot -I${WORKDIR}/recipe-sysroot/usr/include"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://init"
SRC_URI += "file://config.mustache"
SRC_URI += "file://ofac.json"
S = "${WORKDIR}/git"

INITSCRIPT_NAME = "rbuilder"
INITSCRIPT_PARAMS = "defaults 98"

FILES:${PN} += "${sysconfdir}/init.d/rbuilder"
FILES:${PN} += "${sysconfdir}/rbuilder.config.mustache"
FILES:${PN} += "${sysconfdir}/rbuilder.config"
FILES:${PN} += "${sysconfdir}/rbuilder.ofac.json"

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-r -s /bin/false -G eth rbuilder"

do_install:append() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/rbuilder

    # Install config files owned by root, readable by rbuilder
    install -m 0644 ${THISDIR}/config.mustache ${D}${sysconfdir}/rbuilder.config.mustache
    install -m 0640 ${THISDIR}/config.mustache ${D}${sysconfdir}/rbuilder.config
    install -m 0644 ${THISDIR}/ofac.json ${D}${sysconfdir}/rbuilder.ofac.json

    # Ensure rbuilder can read these files
    chown rbuilder:rbuilder ${D}${sysconfdir}/rbuilder.config
    chown rbuilder:rbuilder ${D}${sysconfdir}/rbuilder.ofac.json
}
TOOLCHAIN = "clang"
