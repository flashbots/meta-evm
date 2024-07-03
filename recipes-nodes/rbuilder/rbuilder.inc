SUMMARY = "Rust Builder"
DESCRIPTION = "Rust builder running with a full ethereum node (reth) implemented in rust."
LICENSE="CLOSED"
LIC_FILES_CHKSUM=""

inherit cargo_bin update-rc.d

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

DEPENDS += "libffi openssl"
RDEPENDS:${PN} += "libffi openssl reth cvm-reverse-proxy config-parser"

export BINDGEN_EXTRA_CLANG_ARGS
BINDGEN_EXTRA_CLANG_ARGS = "--sysroot=${WORKDIR}/recipe-sysroot -I${WORKDIR}/recipe-sysroot/usr/include"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://init"
SRC_URI += "file://config"
SRC_URI += "file://ofac.json"
S = "${WORKDIR}/git"

INITSCRIPT_NAME = "rbuilder"
INITSCRIPT_PARAMS = "defaults 99" 

FILES:${PN} += "${sysconfdir}/init.d/rbuilder"
FILES:${PN} += "${sysconfdir}/rbuilder.config"
FILES:${PN} += "${sysconfdir}/rbuilder.ofac.json"

do_install:append() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${THISDIR}/init ${D}${sysconfdir}/init.d/rbuilder
    install -m 0755 ${THISDIR}/config ${D}${sysconfdir}/rbuilder.config
    install -m 0755 ${THISDIR}/ofac.json ${D}${sysconfdir}/rbuilder.ofac.json
}
TOOLCHAIN = "clang"
